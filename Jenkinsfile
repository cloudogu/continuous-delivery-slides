#!groovy

//Keep this version in sync with the one used in Maven.pom-->
@Library('github.com/cloudogu/ces-build-lib@d57af485')
import com.cloudogu.ces.cesbuildlib.*

node('docker') {

    properties([
            // Keep only the last 10 build to preserve space
            buildDiscarder(logRotator(numToKeepStr: '10')),
            // Don't run concurrent builds for a branch, because they use the same workspace directory
            disableConcurrentBuilds(),
            parameters([
                    booleanParam(name: 'deployToNexus', defaultValue: false,
                            description: 'Deploying to Nexus tages ~10 Min since Nexus 3. That\'s why we skip it be default'),
                    booleanParam(name: 'deployToK8s', defaultValue: false,
                            description: 'Deploys to Kubernetes. We deploy to GitHub pages, so skip deploying to k8s by default.')
            ])
    ])

    def introSlidePath = 'docs/slides/01-intro.md'

    Git git = new Git(this, 'cesmarvin')
    Docker docker = new Docker(this)

    catchError {

        Maven mvn = new MavenInDocker(this, "3.5.0-jdk-8")

        stage('Checkout') {
            checkout scm
            git.clean('')
        }

        String versionName = createVersion(mvn)

        stage('Build') {
            docker.image('node:11.14.0-alpine')
              // Avoid  EACCES: permission denied, mkdir '/.npm'
              .mountJenkinsUser()
              .inside {
                echo 'Building presentation'
                sh 'npm install'
                // Don't run tests, because we're not developing reveal here
                sh 'node_modules/grunt/bin/grunt package --skipTests'
            }
        }

        stage('package') {
            // "unzip" is not installed by default on many systems, so use it within a container
            docker.image('garthk/unzip').inside {
                sh 'unzip reveal-js-presentation.zip -d dist'
            }

            writeVersionNameToIntroSlide(versionName, introSlidePath)
        }

        stage('Deploy GH Pages') {
            git.pushGitHubPagesBranch('dist', versionName)
        }

        stage('Deploy Nexus') {
            if (params.deployToNexus) {

                mvn.useDeploymentRepository([
                        // Must match the one in pom.xml!
                        id: 'ecosystem.cloudogu.com',
                        credentialsId: 'ces-nexus'
                ])

                // Artifact is used in pom.xml
                mvn.deploySiteToNexus("-Dartifact=${env.BRANCH_NAME} ")
            } else {
                echo "Skipping deployment to Nexus because parameter is set to false."
            }
        }

        stage('Deploy Kubernetes') {
            if (params.deployToK8s) {
                deployToKubernetes(versionName)
            } else {
                echo "Skipping deployment to Kubernetes because parameter is set to false."
            }
        }
    }

    mailIfStatusChanged(git.commitAuthorEmail)
}

String createVersion(Maven mvn) {
    // E.g. "201708140933-1674930"
    String versionName = "${new Date().format('yyyyMMddHHmm')}-${new Git(this).commitHashShort}"

    if (env.BRANCH_NAME == "master") {
        mvn.additionalArgs = "-Drevision=${versionName} "
        currentBuild.description = versionName
        echo "Building version $versionName on branch ${env.BRANCH_NAME}"
    } else {
        versionName += '-SNAPSHOT'
    }
    return versionName
}

private void writeVersionNameToIntroSlide(String versionName, String introSlidePath) {
    def distIntro = "dist/${introSlidePath}"
    String filteredIntro = filterFile(distIntro, "<!--VERSION-->", "Version: $versionName")
    sh "cp $filteredIntro $distIntro"
    sh "mv $filteredIntro $introSlidePath"
}

void deployToKubernetes(String versionName) {

    String imageName = "cloudogu/continuous-delivery-slides:${versionName}"
    def image = docker.build imageName
    docker.withRegistry('', 'hub.docker.com-cesmarvin') {
        image.push()
        image.push('latest')
    }

    withCredentials([file(credentialsId: 'kubeconfig-oss-deployer', variable: 'kubeconfig')]) {

        withEnv(["IMAGE_NAME=$imageName"]) {

            kubernetesDeploy(
                    credentialsType: 'KubeConfig',
                    kubeConfig: [path: kubeconfig],

                    configs: 'k8s.yaml',
                    enableConfigSubstitution: true
            )
        }
    }
}

/**
 * Filters a {@code filePath}, replacing an {@code expression} by {@code replace} writing to new file, whose path is returned.
 *
 * @return path to filtered file
 */
String filterFile(String filePath, String expression, String replace) {
    String filteredFilePath = filePath + ".filtered"
    // Fail command (and build) if file not present
    sh "test -e ${filePath} || (echo Title slide ${filePath} not found && return 1)"
    sh "cat ${filePath} | sed 's/${expression}/${replace}/g' > ${filteredFilePath}"
    return filteredFilePath
}
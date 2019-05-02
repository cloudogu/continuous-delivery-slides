#!groovy

//Keep this version in sync with the one used in Maven.pom-->
@Library('github.com/cloudogu/ces-build-lib@76fbd0aa')
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

    catchError {

        Maven mvn = new MavenInDocker(this, "3.5.0-jdk-8")

        stage('Checkout') {
            checkout scm
            git.clean('')
        }

        String versionName = createVersion(mvn)

        stage('Build') {
            docker.image('node:11.14.0-stretch')
              // ove rride entrypoint, because of https://issues.jenkins-ci.org/browse/JENKINS-41316
              .inside('--entrypoint=""') {
                echo 'Building presentation'
                sh 'yarn install'
                  // Don't run tests, because we're not developing reveal here
                  sh 'node_modules/grunt/bin/grunt package --skipTests'
            }
        }

        stage('package') {
            // "unzip" is not installed by default on many systems, so use it within a container
            docker.image('garthk/unzip')
               // override entrypoint, because of https://issues.jenkins-ci.org/browse/JENKINS-41316
              .inside('--entrypoint=""') {
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
                        credentialsId: 'jenkins'
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

    String dockerRegistry = 'eu.gcr.io/cloudogu-backend'
    String imageName = "$dockerRegistry/continuous-delivery-slides-example:${versionName}"

    docker.withRegistry("https://$dockerRegistry", 'gcloud-docker') {
        docker.build(imageName, '.').push()
    }

    withCredentials([file(credentialsId: 'kubeconfig-bc-production', variable: 'kubeconfig')]) {

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
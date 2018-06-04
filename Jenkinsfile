#!groovy
@Library('github.com/cloudogu/ces-build-lib@b5ce9f1')
import com.cloudogu.ces.cesbuildlib.*

node('docker') {

    properties([
            // Keep only the last 10 build to preserve space
            buildDiscarder(logRotator(numToKeepStr: '10')),
            // Don't run concurrent builds for a branch, because they use the same workspace directory
            disableConcurrentBuilds()
    ])

    String defaultEmailRecipients = env.EMAIL_RECIPIENTS

    catchError {

        Maven mvn = new MavenInDocker(this, "3.5.0-jdk-8")
        Git git = new Git(this)

        stage('Checkout') {
            checkout scm
            git.clean('')
        }

        String versionName = createVersion(mvn)


        stage('Build') {
            new Docker(this).image('kkarczmarczyk/node-yarn:8.0-wheezy').mountJenkinsUser()
              // override entrypoint, because of https://issues.jenkins-ci.org/browse/JENKINS-41316
              .inside('--entrypoint=""') {
                echo 'Building presentation'
                sh 'yarn install'
                sh 'node_modules/grunt/bin/grunt package'
            }
        }

        stage('package') {
            // This could probably be done easier...
            docker.image('garthk/unzip')
               // override entrypoint, because of https://issues.jenkins-ci.org/browse/JENKINS-41316
              .inside('--entrypoint=""') {
                sh 'unzip reveal-js-presentation.zip -d dist'
            }

            writeVersionNameToIntroSlide(versionName)
        }

        stage('Deploy Nexus') {
            String usernameProperty = "site_username"
            String passwordProperty = "site_password"

            String settingsXmlPath = mvn.writeSettingsXmlWithServer(
                    // From pom.xml
                    'ecosystem.cloudogu.com',
                    "\${env.${usernameProperty}}",
                    "\${env.${passwordProperty}}")

            withCredentials([usernamePassword(credentialsId: 'jenkins',
                    passwordVariable: passwordProperty, usernameVariable: usernameProperty)]) {

                mvn "site:deploy -s \"${settingsXmlPath}\" -Dartifact=${env.BRANCH_NAME}"
            }
        }

        stage('Deploy Kubernetes') {
            if (env.BRANCH_NAME == 'master') {
                deployToKubernetes(versionName)
            } else {
                echo "Skipping deployment to Kubernetes because current branch is ${env.BRANCH_NAME}."
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

private void writeVersionNameToIntroSlide(String versionName) {
    def distIntro = 'dist/docs/slides/01-intro.md'
    def originalIntro = 'docs/slides/01-intro.md'
    String filteredIntro = filterFile(distIntro, "<!--VERSION-->", "Stand: $versionName")
    sh "cp $filteredIntro $distIntro"
    sh "mv $filteredIntro $originalIntro"
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
    sh "cat ${filePath} | sed 's/${expression}/${replace}/g' > ${filteredFilePath}"
    return filteredFilePath
}

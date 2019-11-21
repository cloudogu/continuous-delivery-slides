#!groovy

//Keep this version in sync with the one used in Maven.pom-->
@Library('github.com/cloudogu/ces-build-lib@b49dce93')
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
                            description: 'Deploys to Kubernetes. We deploy to GitHub pages, so skip deploying to k8s by default.'),
                    booleanParam(defaultValue: false, name: 'forceDeployGhPages',
                            description: 'GH Pages are deployed on Master Branch only. If this box is checked it\'s deployed no what Branch is built.')
            ])
    ])

    def introSlidePath = 'docs/slides/01-intro.md'
    nodeImageVersion = 'node:11.15.0-alpine'
    headlessChromeVersion = 'yukinying/chrome-headless-browser:80.0.3970.5'

    Git git = new Git(this, 'cesmarvin')
    Docker docker = new Docker(this)
    Maven mvn = new MavenInDocker(this, "3.6.2-jdk-8")
    forceDeployGhPages = Boolean.valueOf(params.forceDeployGhPages)


    catchError {

        stage('Checkout') {
            checkout scm
            git.clean('')
        }

        String versionName = createVersion(mvn)
        String pdfPath = createPdfName()

        stage('Build') {
            docker.image(nodeImageVersion)
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

        stage('print pdf') {
            printPdf pdfPath
            archiveArtifacts pdfPath
            // Make world readable (useful when accessing from docker)
            sh "chmod og+r '${pdfPath}'"
            // Deploy PDF next to the app, use a constant name for the PDF for easier URLs.
            sh "mv '${pdfPath}' 'dist/${createPdfName(false)}'"
        }

        stage('Deploy GH Pages') {
            if (env.BRANCH_NAME == 'master' || forceDeployGhPages) {
                git.pushGitHubPagesBranch('dist', versionName)
            } else {
                echo "Skipping deploy to GH pages, because not on master branch"
            }
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

String nodeImageVersion
String headlessChromeVersion

String createPdfName(boolean includeDate = true) {
    String title = sh (returnStdout: true, script: "grep -r '<title>' index.html | sed 's/.*<title>\\(.*\\)<.*/\\1/'").trim()
    String pdfName = '';
    if (includeDate) {
        pdfName = "${new Date().format('yyyy-MM-dd')}-"
    }
    pdfName += "${title}.pdf"
    return pdfName
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

void writeVersionNameToIntroSlide(String versionName, String introSlidePath) {
    def distIntro = "dist/${introSlidePath}"
    String filteredIntro = filterFile(distIntro, "<!--VERSION-->", "Version: $versionName")
    sh "cp $filteredIntro $distIntro"
    sh "mv $filteredIntro $introSlidePath"
}

void printPdf(String pdfPath) {
    Docker docker = new Docker(this)

    docker.image(nodeImageVersion).withRun(
            "-v ${WORKSPACE}:/workspace -w /workspace",
            'npm run start') { revealContainer ->

        def revealIp = docker.findIp(revealContainer)
        if (!revealIp || !waitForWebserver("http://${revealIp}:8000")) {
            echo "Warning: Couldn't deploy reveal presentation for PDF printing. "
            echo "Docker log:"
            echo new Sh(this).returnStdOut("docker logs ${revealContainer.id}")
            error "PDF creation failed"
        }

        docker.image(headlessChromeVersion)
                // Chromium writes to $HOME/local, so we need an entry in /etc/pwd for the current user
                .mountJenkinsUser()
                // Try to avoid OOM for larger presentations by setting larger shared memory
                .inside("--shm-size=2G") {

            sh "/usr/bin/google-chrome-unstable --headless --no-sandbox --disable-gpu --print-to-pdf='${pdfPath}' " +
                    "http://${revealIp}:8000/?print-pdf"
        }
    }
}

void deployToKubernetes(String versionName) {

    String imageName = "cloudogu/continuous-delivery-slides:${versionName}"

    sh 'cp Dockerfile dist/ && cp .dockerignore dist/'
    dir ('dist') {
        def image = docker.build imageName
        docker.withRegistry('', 'hub.docker.com-cesmarvin') {
            image.push()
            image.push('latest')
        }
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

boolean waitForWebserver(String url) {
    echo "Waiting for website to become ready at ${url}"
    // Output to stdout and discard (O- >/dev/null) because we don't want the file we only want to know if it's available
    int ret = sh (returnStatus: true, script: "wget -O- --retry-connrefused --tries=30 -q --wait=1 ${url} &> /dev/null")
    return ret == 0
}
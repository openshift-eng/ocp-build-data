@Library('art-ci-toolkit@master') _

pipeline {
    agent {
        docker {
            image "openshift-art/art-ci-toolkit:latest"
            alwaysPull true
            args "--entrypoint=''"
        }
    }
    stages {
        stage("validate modified files") {
            when { changeRequest() }
            steps {
                sshagent (credentials: ['openshift-bot']) {
                    ocpBuildDataCISteps()
                }
            }
        }
    }
}

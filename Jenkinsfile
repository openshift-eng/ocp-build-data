@Library('art-ci-toolkit@master') _

pipeline {
    agent {
        docker {
            image "redhat/art-tools-ci:latest"
            alwaysPull true
            args "--entrypoint=''"
        }
    }
    stages {
        stage("validate modified files") {
            when { changeRequest() }
            steps { ocpBuildDataCISteps() }
        }
    }
}

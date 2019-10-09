def getModifiedFiles() {
    sh(
        returnStdout: true,
        script: """
        git diff --name-only \$(git ls-remote origin --tags ${env.CHANGE_BRANCH} | cut -f1) \
        ${env.GIT_COMMIT}
        """
    ).trim().split("\n").findAll { it.endsWith(".yml") }
}

def commentOnPullRequest(msg) {
    withCredentials([string(
        credentialsId: "openshift-bot-token",
        variable: "GITHUB_TOKEN"
    )]) {
        script {
            writeFile(
                file: "msg.txt",
                text: msg
            )
            requestBody = sh(
                returnStdout: true,
                script: "jq --rawfile msg msg.txt -nr '{\"body\": \$msg}'"
            )
            repositoryName = env.GIT_URL
                .replace("https://github.com/", "")
                .replace(".git", "")

            httpRequest(
                contentType: 'APPLICATION_JSON',
                customHeaders: [[
                    maskValue: true,
                    name: 'Authorization',
                    value: "token ${env.GITHUB_TOKEN}"
                ]],
                httpMode: 'POST',
                requestBody: requestBody,
                responseHandle: 'NONE',
                url: "https://api.github.com/repos/${repositoryName}/issues/${env.CHANGE_ID}/comments"
            )
        }
    }
}

pipeline {
    agent {
        docker {
            image "redhat/art-tools-ci:latest"
            args "--entrypoint=''"
        }
    }
    stages {
        stage("validate modified files") {
            when {
                changeRequest()
            }
            steps {
                script {
                    sh 'printenv'
                    modifiedFiles = getModifiedFiles()

                    if ("group.yml" in modifiedFiles || "streams.yml" in modifiedFiles) {
                        modifiedFiles = ["{images,rpms}/*"]
                    }

                    catchError(stageResult: 'FAILURE') {
                        if (modifiedFiles.isEmpty()) {
                            sh "echo 'No files to validate' > results.txt"
                        } else {
                            sh "validate-ocp-build-data ${modifiedFiles.join(" ")} > results.txt 2>&1"
                        }
                    }

                    results = readFile("results.txt").trim()
                    echo results
                    commentOnPullRequest("### Build <span>#</span>${env.BUILD_NUMBER}\n```\n${results}\n```")
                }
            }
        }
    }
}

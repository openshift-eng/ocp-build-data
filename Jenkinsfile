// Upshift Jenkinsfile.
// vi: syntax=groovy

node {
    checkout scm;
    def jobspec = readYaml(file: 'jobspec.yaml');
    def git_url = jobspec.recipe.git_url
    def git_ref = jobspec.recipe.git_ref
    def os_name = jobspec.job.os_name

    echo("""
Requesting build for:
    OS Name: ${os_name}
  Spec File: ${env.WORKSPACE}/jobspec.yaml

Checking out Upshift Pipeline from:
   Git URL: ${git_url}
   Git Ref: ${git_ref}

""")

    // Checkout the RHCOS pipeline _and_ version that we want.
    sh("""
set -xeuo pipefail
git config --global http.sslCAInfo ${env.WORKSPACE}/ca.crt
rm -rf ${env.WORKSPACE}/pipeline
git clone ${git_url} ${env.WORKSPACE}/pipeline
pushd ${env.WORKSPACE}/pipeline
git reset --hard ${git_ref}
git log -1
""")

    build = load "${env.WORKSPACE}/pipeline/upshift/osbuild.groovy";
    build.runPodTemplate(os_name, "${env.WORKSPACE}/jobspec.yaml")
}

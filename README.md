Unless otherwise required, repositories which contribute RPMs and images to the OCP build should:
- Place single RPM spec file in the root of the repository.
    - The .spec should be based on the template here: https://github.com/openshift/release/blob/a848bc5df06b4e7c38568beeae725e301bb7ea5e/tools/hack/golang/package.spec
- Place Dockerfiles in images/some-name path.
    - Read the example Dockerfiles in this repo for more details about the content of these Dockerfiles.


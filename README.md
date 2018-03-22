Unless otherwise required, repositories which contribute RPMs and images to the OCP build should:
- Place single RPM spec file in the root of the repository.
    - This spec should include a %commit variable as shown in myutil.spec.
- Place Dockerfiles in images/some-name path.
    - Read the example Dockerfiles in this repo for more details about the content of these Dockerfiles.


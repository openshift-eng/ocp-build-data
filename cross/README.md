# Cross-toolchain source bundle

`build-cross-tarball.sh` creates the `cross.tar.gz` source bundle consumed by
the OpenShift Golang builder images. The following workflow builds a candidate
archive and publishes it to the OpenShift artifacts server for testing.

## Obtain the macOS SDK

The builder requires `MacOSX10.15.sdk.tar.xz`. Bootstrap the local SDK input
from the currently published cross-toolchain bundle. The download is roughly
569 MB, but only the SDK member is extracted:

```console
$ mkdir -p /tmp/openshift-golang-builder-cross-sdk
$ curl --fail --location \
    --output /tmp/openshift-golang-builder-cross-sdk/cross.tar.gz \
    https://ocp-artifacts.engineering.redhat.com/pub/RHOCP/build-deps/openshift-golang-builder/cross.tar.gz
$ tar -xzf /tmp/openshift-golang-builder-cross-sdk/cross.tar.gz \
    -C /tmp/openshift-golang-builder-cross-sdk \
    --strip-components=3 \
    cross/osxcross/tarballs/MacOSX10.15.sdk.tar.xz
```

Verify the extracted SDK against the checksum expected by the builder:

```console
$ sha256sum /tmp/openshift-golang-builder-cross-sdk/MacOSX10.15.sdk.tar.xz
05c98ed96b677dfba862356cba317cdcb7bfdff973150a60e0d1027da705c4cc  /tmp/openshift-golang-builder-cross-sdk/MacOSX10.15.sdk.tar.xz
```

## Build the archive

Run the builder from the root of the `ocp-build-data` checkout using the
verified SDK:

```console
$ ./cross/build-cross-tarball.sh \
    --sdk /tmp/openshift-golang-builder-cross-sdk/MacOSX10.15.sdk.tar.xz \
    --output cross-new.tar.gz
```

Record the resulting checksum before transferring the file:

```console
$ sha256sum cross-new.tar.gz
```

## Stage the archive on `file.corp`

Copy the candidate archive to the public staging area. This makes it available
to the artifacts host over HTTPS.

```console
$ scp cross-new.tar.gz sidsharm@file.corp.redhat.com:~/public_html
```

The staged file is available at:

```text
https://file.corp.redhat.com/~sidsharm/cross-new.tar.gz
```

## Connect to the artifacts host

Connect to the ART build VM:

```console
$ virtctl -n art--runtime-int ssh sidsharm@buildvm
```

On `buildvm`, switch to the Jenkins account:

```console
[sidsharm@buildvm ~]$ sudo -i -u jenkins
```

From the Jenkins shell, connect to the artifacts host:

```console
[jenkins@buildvm ~]$ ssh ocp-artifacts
```

## Publish the archive

Download the staged archive and generate its checksum file on `ocp-artifacts`:

```console
$ curl --fail --location --remote-name \
    https://file.corp.redhat.com/~sidsharm/cross-new.tar.gz
$ sha256sum cross-new.tar.gz > sha256sum-new.txt
```

Move both files into the Golang builder artifacts directory:

```console
$ mv cross-new.tar.gz sha256sum-new.txt \
    /mnt/data/pub/RHOCP/build-deps/openshift-golang-builder/
```

## Apply SELinux labels

The nginx container can only read files labeled with the `container_file_t`
type. Files left as `unlabeled_t` are not visible to the container. Copy the
labels from the existing archive and checksum files:

```console
$ chcon \
    --reference=/mnt/data/pub/RHOCP/build-deps/openshift-golang-builder/cross.tar.gz \
    /mnt/data/pub/RHOCP/build-deps/openshift-golang-builder/cross-new.tar.gz
$ chcon \
    --reference=/mnt/data/pub/RHOCP/build-deps/openshift-golang-builder/sha256sum.txt \
    /mnt/data/pub/RHOCP/build-deps/openshift-golang-builder/sha256sum-new.txt
```

Confirm the ownership, permissions, and SELinux labels:

```console
$ ls -laZ /mnt/data/pub/RHOCP/build-deps/openshift-golang-builder/
```

## Verify the published files

Download the published archive and checksum from a machine with access to the
artifacts server, then verify them together:

```console
$ cd /tmp
$ curl --fail --location --remote-name \
    https://ocp-artifacts.engineering.redhat.com/pub/RHOCP/build-deps/openshift-golang-builder/cross-new.tar.gz
$ curl --fail --location --remote-name \
    https://ocp-artifacts.engineering.redhat.com/pub/RHOCP/build-deps/openshift-golang-builder/sha256sum-new.txt
$ sha256sum --check sha256sum-new.txt
```

A successful verification prints `cross-new.tar.gz: OK`.

## Test the archive in Konflux

Create an `ocp-build-data` branch from the release branch that should consume
the candidate archive. In the target Golang builder image metadata, update the
Konflux artifact lockfile resource while retaining `cross.tar.gz` as the local
filename expected by the Dockerfile:

```yaml
konflux:
  cachi2:
    artifact_lockfile:
      resources:
      - url: https://ocp-artifacts.engineering.redhat.com/pub/RHOCP/build-deps/openshift-golang-builder/cross-new.tar.gz
        filename: cross.tar.gz
```

Open a PR against that release branch. See
[ocp-build-data PR #11873](https://github.com/openshift-eng/ocp-build-data/pull/11873)
for an example that changes only the RHEL 9.6 Konflux configuration.

In Jenkins, open the Golang builder job and select **Build with Parameters**.
Set **Doozer data Git ref** to the source branch of the test PR and set
**Build system** to `konflux`. For PR #11873, the Doozer data Git ref is
`test-cross-new-rhel9-golang-1.25`. Start the job, then confirm that the
resulting Konflux build downloads the candidate archive and completes the
cross-toolchain steps successfully.

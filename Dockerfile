FROM brew.registry.redhat.io/rh-osbs/openshift-golang-builder:v1.22.7-202410111609.gc451559.el9

# Start Konflux-specific steps
RUN mkdir -p /tmp/yum_temp; mv /etc/yum.repos.d/*.repo /tmp/yum_temp/ || true
COPY .oit/unsigned.repo /etc/yum.repos.d/
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem /tmp
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202410251504.p0.gfb58804.assembly.test.el9 BUILD_VERSION=v4.18.0 CI_RPM_SVC=base-4-18-rhel9.ocp.svc OS_GIT_MAJOR=4 OS_GIT_MINOR=18 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=4.18.0-202410251504.p0.gfb58804.assembly.test.el9 SOURCE_GIT_TREE_STATE=clean __doozer_group=openshift-4.18 __doozer_key=ci-openshift-golang-builder-latest.rhel9 __doozer_uuid_tag=ci-openshift-golang-builder-latest-rhel9-v4.18.0-20241025.150500 __doozer_version=v4.18.0 
ENV __doozer=merge OS_GIT_COMMIT=fb58804 OS_GIT_VERSION=4.18.0-202410251504.p0.gfb58804.assembly.test.el9-fb58804 SOURCE_DATE_EPOCH=1729868363 SOURCE_GIT_COMMIT=fb588046251406fe7ce39850dac1b7ddd02dd9c0 SOURCE_GIT_TAG=openshift-4.0-archived-3606-gfb588046 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 

# Used by builds scripts to detect whether they are running in the context
# of OpenShift CI or elsewhere (e.g. brew).
ENV OPENSHIFT_CI="true"

ENV GOARM=5 \
    LOGNAME=deadbeef \
    GOCACHE=/go/.cache \
    GOPATH=/go \
    LOGNAME=deadbeef
ENV PATH=$PATH:$GOPATH/bin

# make go related directories writeable since builds in CI will run as non-root.
RUN mkdir -p $GOPATH && \
    chmod g+xw -R $GOPATH && \
    chmod g+xw -R $(go env GOROOT)

# Ensure that repo files can be written by non-root users at runtime so that repos
# can be resolved on build farms and written into yum.repos.d.
RUN chmod 777 /etc/yum.repos.d/

# Install the dnf/yum wrapper that will work for CI workloads.
ENV DNF_WRAPPER_DIR=/bin/dnf_wrapper
ADD ci_images/dnf_wrapper.sh /tmp
ADD ci_images/install_dnf_wrapper.sh /tmp
RUN chmod +x /tmp/*.sh && \
    /tmp/install_dnf_wrapper.sh
# Ensure dnf wrapper scripts appear before anything else in the $PATH
ENV PATH=$DNF_WRAPPER_DIR:$PATH
# Add the doozer repos so that someone connected to the VPN can use those
# repositories. The dnf_wrapper will enable these repos if it detects
# it is not running on a build farm.
ADD .oit/unsigned.repo $DNF_WRAPPER_DIR/


# Start Konflux-specific steps
RUN cp /tmp/yum_temp/* /etc/yum.repos.d/ || true
# End Konflux-specific steps

LABEL \
        io.k8s.description="golang 1.22 builder image for Red Hat CI" \
        name="openshift/ci-openshift-golang-builder-latest-rhel9" \
        com.redhat.component="ci-openshift-golang-builder-latest-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Release" \
        version="v4.18.0" \
        release="202410251504.p0.gfb58804.assembly.test.el9" \
        io.openshift.build.commit.id="fb588046251406fe7ce39850dac1b7ddd02dd9c0" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/fb588046251406fe7ce39850dac1b7ddd02dd9c0"


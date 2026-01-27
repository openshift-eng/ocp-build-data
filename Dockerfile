FROM brew.registry.redhat.io/rh-osbs/ubi8@sha256:143123d85045df426c5bbafc6863659880ebe276eb02c77ee868b88d08dbd05d

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=open
RUN go clean -cache || true
ENV ART_BUILD_DEPS_MODE=default
USER 0
RUN mkdir -p /tmp/art/yum_temp; mv /etc/yum.repos.d/*.repo /tmp/art/yum_temp/ || true
COPY .oit/art-unsigned.repo /etc/yum.repos.d/
RUN curl https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem /tmp/art
# End Konflux-specific steps
ENV __doozer=update __doozer_group=rhel-8-golang-1.22 __doozer_key=openshift-golang-builder __doozer_uuid_tag=golang-builder-v1.22.12-20260127.162035 __doozer_version=v1.22.12 

ARG GOPATH
ENV SUMMARY="RHEL8 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=${GOPATH:-/go} \
    GOMAXPROCS=8 \
    VERSION="1.22" \
    GO_VERSION="${__doozer_version:-$VERSION}" \
    GODEBUG="disablethp=1"


RUN dnf update -y && \
    dnf install -y --nodocs \
        bc \
        diffutils \
        dos2unix \
        file \
        findutils \
        git \
        goversioninfo \
        gpgme \
        gpgme-devel \
        hostname \
        libassuan-devel \
        libtool \
        lsof \
        make \
        openssl \
        openssl-devel \
        patch \
        python3 \
        rsync \
        socat \
        systemd-devel \
        tar \
        tree \
        util-linux \
        wget \
        which \
        xz \
        zip && \
    dnf install -y "golang-*$VERSION*" && \
    mkdir -p /go/src
# provide a cross-compiler for windows/mac binaries (amd64 only)
RUN cp /cachi2/output/deps/generic/cross.tar.gz .
RUN [ $(go env GOARCH) != "amd64" ] || (\
    # only install cross-compiler dependencies on amd64
    yum install -y --setopt=tsflags=nodocs \
    # Required packages for mac cross-compilation
    llvm-toolset-17* cmake3 gcc-c++ libxml2-devel \
    # Required packages for windows cross-compilation
    glibc mingw64-gcc && \
    # compile macos cross-compilers
    tar zfx cross.tar.gz && \
    export TP_OSXCROSS_DEV=$(pwd)/cross/deps && \
    pushd cross/osxcross && \
    UNATTENDED=yes ./build.sh && \
    popd && \
    cp -avr cross/osxcross/target/bin/* /usr/local/bin/ && \
    cp -avr cross/osxcross/target/lib/* /usr/local/lib64/ && \
    cp -avr cross/osxcross/target/SDK /usr/local/SDK && \
    echo /usr/local/lib64 > /etc/ld.so.conf.d/local.conf && \
    /sbin/ldconfig && \
    rm -rf cross)

# above is conditional; clean up unconditionally
RUN rm -f cross.tar.gz && yum clean all -y

# FOD wrapper modification
COPY go_wrapper.sh /tmp/go_wrapper.sh
RUN GO_BIN_PATH=$(which go) && mv $GO_BIN_PATH $GO_BIN_PATH.real && mv /tmp/go_wrapper.sh $GO_BIN_PATH && chmod +x $GO_BIN_PATH

# Start Konflux-specific steps
USER 0
RUN rm -f /etc/yum.repos.d/art-* && mv /tmp/art/yum_temp/* /etc/yum.repos.d/ || true
RUN rm -rf /tmp/art

# End Konflux-specific steps

LABEL \
        summary="RHEL8 based Go builder image for OpenShift ART" \
        description="RHEL8 based Go builder image for OpenShift ART" \
        io.k8s.description="golang builder image for Red Hat internal builds" \
        io.k8s.display-name="Go Builder 1.22" \
        com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
        version="v1.22.12" \
        name="openshift/golang-builder" \
        vendor="Red Hat, Inc." \
        cpe="cpe:/a:redhat:openshift:1.22::el8" \
        com.redhat.component="openshift-golang-builder-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Security" \
        release="202601271620.ge50a287.el8" \
        io.openshift.build.commit.id="e50a2876781fb3b19b9d6ba4f8814e8f67f07b0f" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/e50a2876781fb3b19b9d6ba4f8814e8f67f07b0f" \
        io.openshift.tags="Empty"


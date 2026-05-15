FROM brew.registry.redhat.io/rh-osbs/rhel-els@sha256:2aaaf576ca73226a6f00af0fd0f0f1e08d5f6a269d15f9b5305d3d5bde94d4f7

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=hermetic
RUN go clean -cache || true
ENV ART_BUILD_DEPS_MODE=default
# End Konflux-specific steps
ENV __doozer=update __doozer_group=rhel-9-golang-1.26 __doozer_key=openshift-golang-builder __doozer_uuid_tag=golang-builder-v1.26.2-20260515.195216 __doozer_version=v1.26.2 

ARG GOPATH
ENV SUMMARY="RHEL9 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=${GOPATH:-/go} \
    GOMAXPROCS=8 \
    GOAMD64=v2 \
    VERSION="1.26" \
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
        krb5-devel \
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
    llvm-toolset cmake3 gcc-c++ libxml2-devel \
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

LABEL \
        summary="RHEL9 based Go builder image for OpenShift ART" \
        description="RHEL9 based Go builder image for OpenShift ART" \
        io.k8s.description="golang builder image for Red Hat internal builds" \
        io.k8s.display-name="Go Builder 1.26" \
        com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
        version="v1.26.2" \
        name="openshift/golang-builder" \
        vendor="Red Hat, Inc." \
        cpe="cpe:/a:redhat:openshift:1.26::el9" \
        com.redhat.component="openshift-golang-builder-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Security" \
        release="202605151952.p2.g5943cad.el9" \
        io.openshift.build.commit.id="5943cadc45e621be19cac9170a6418bd9e9b177a" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/5943cadc45e621be19cac9170a6418bd9e9b177a" \
        io.openshift.tags="Empty"


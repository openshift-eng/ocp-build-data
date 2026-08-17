FROM brew.registry.redhat.io/rh-osbs/rhel-els@sha256:2aaaf576ca73226a6f00af0fd0f0f1e08d5f6a269d15f9b5305d3d5bde94d4f7

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=hermetic
RUN go clean -cache || true
ENV ART_BUILD_DEPS_MODE=default
USER 0
# End Konflux-specific steps
ENV __doozer=update __doozer_golang_nvr=golang-1.24.13-11.el9_8 __doozer_group=golang __doozer_key=openshift-golang-builder-1-24.rhel9 __doozer_uuid_tag=golang-builder-v1.24.13-20260817.204534 __doozer_version=v1.24.13 

ARG GOPATH
ENV SUMMARY="RHEL9 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=${GOPATH:-/go} \
    GOMAXPROCS=8 \
    GOAMD64=v2 \
    VERSION="1.24" \
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
    dnf install -y "$__doozer_golang_nvr" && \
    mkdir -p /go/src
# provide a cross-compiler for windows/mac binaries (x86_64 only)
RUN cp /cachi2/output/deps/generic/cross.tar.gz .
RUN if [ "$(uname -m)" = "x86_64" ]; then \
    # only install cross-compiler dependencies on x86_64
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
    rm -rf cross; \
fi

# above is conditional; clean up unconditionally
RUN rm -f cross.tar.gz && yum clean all -y

# FOD wrapper modification
COPY go_wrapper.sh /tmp/go_wrapper.sh
RUN GO_BIN_PATH=$(which go) && mv $GO_BIN_PATH $GO_BIN_PATH.real && mv /tmp/go_wrapper.sh $GO_BIN_PATH && chmod +x $GO_BIN_PATH

LABEL \
        summary="RHEL9 based Go builder image for OpenShift ART" \
        description="RHEL9 based Go builder image for OpenShift ART" \
        io.k8s.description="golang builder image for Red Hat internal builds" \
        io.k8s.display-name="Go Builder 1.24" \
        com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
        version="v1.24.13" \
        name="openshift/golang-builder" \
        vendor="Red Hat, Inc." \
        cpe="cpe:/a:redhat:openshift:1.24::el9" \
        com.redhat.component="openshift-golang-builder-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Security" \
        release="202608172045.p2.gedd1cdd.assembly.stream.el9" \
        io.openshift.build.golang-nvr="golang-1.24.13-11.el9_8" \
        io.openshift.build.commit.id="edd1cdd743394dd54c333edc22eba561eaf6de79" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/edd1cdd743394dd54c333edc22eba561eaf6de79" \
        io.openshift.tags="Empty"


FROM brew.registry.redhat.io/rh-osbs/rhel-els@sha256:2aaaf576ca73226a6f00af0fd0f0f1e08d5f6a269d15f9b5305d3d5bde94d4f7

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=open
RUN go clean -cache || true
ENV REMOTE_SOURCES=cachito-emulation
ENV REMOTE_SOURCES_DIR=/tmp/art/cachito-emulation
COPY . $REMOTE_SOURCES_DIR/cachito-gomod-with-deps/app/
RUN curl https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem $REMOTE_SOURCES_DIR/cachito-gomod-with-deps/app/registry-ca.pem
ENV ART_BUILD_DEPS_MODE=cachito-emulation
USER 0
RUN mkdir -p /tmp/art/yum_temp; mv /etc/yum.repos.d/*.repo /tmp/art/yum_temp/ || true
COPY .oit/art-unsigned.repo /etc/yum.repos.d/
RUN curl https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem /tmp/art
# End Konflux-specific steps
ENV __doozer=update __doozer_group=rhel-9-golang-1.24 __doozer_key=openshift-golang-builder __doozer_uuid_tag=golang-builder-v1.24.6-20251104.100213 __doozer_version=v1.24.6 

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

# Start Konflux-specific steps
USER 0
RUN rm -f /etc/yum.repos.d/art-* && mv /tmp/art/yum_temp/* /etc/yum.repos.d/ || true
RUN rm -rf /tmp/art

# End Konflux-specific steps

LABEL \
        summary="RHEL9 based Go builder image for OpenShift ART" \
        description="RHEL9 based Go builder image for OpenShift ART" \
        io.k8s.description="golang builder image for Red Hat internal builds" \
        io.k8s.display-name="Go Builder 1.24" \
        com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
        version="v1.24.6" \
        name="openshift/golang-builder" \
        vendor="Red Hat, Inc." \
        cpe="cpe:/a:redhat:openshift:1.24::el9" \
        com.redhat.component="openshift-golang-builder-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Security" \
        release=".g4284440.el9" \
        io.openshift.build.commit.id="4284440751e85051a9fbfc934c810798ba15430d" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/4284440751e85051a9fbfc934c810798ba15430d" \
        io.openshift.tags="Empty"


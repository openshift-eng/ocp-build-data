FROM brew.registry.redhat.io/rh-osbs/ubi10:latest

# Start Konflux-specific steps
ENV ART_BUILD_ENGINE=konflux
ENV ART_BUILD_DEPS_METHOD=cachi2
ENV ART_BUILD_NETWORK=hermetic
RUN go clean -cache || true
ENV ART_BUILD_DEPS_MODE=default
USER 0
# End Konflux-specific steps
ENV __doozer=update __doozer_golang_nvr=golang-1.27.4-3.el10_3 __doozer_group=golang __doozer_key=openshift-golang-builder-1-27.rhel10 __doozer_uuid_tag=golang-builder-v1.27.4-20261127.092446 __doozer_version=v1.27.4 

ARG GOPATH
ENV SUMMARY="RHEL10 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=${GOPATH:-/go} \
    GOMAXPROCS=8 \
    GOAMD64=v2 \
    VERSION="1.27" \
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
RUN dnf clean all -y

# FOD wrapper modification
COPY go_wrapper.sh /tmp/go_wrapper.sh
RUN GO_BIN_PATH=$(which go) && mv $GO_BIN_PATH $GO_BIN_PATH.real && mv /tmp/go_wrapper.sh $GO_BIN_PATH && chmod +x $GO_BIN_PATH

LABEL \
        summary="RHEL10 based Go builder image for OpenShift ART" \
        description="RHEL10 based Go builder image for OpenShift ART" \
        io.k8s.description="golang builder image for Red Hat internal builds" \
        io.k8s.display-name="Go Builder 1.27" \
        com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
        version="v1.27.4" \
        name="openshift/golang-builder" \
        vendor="Red Hat, Inc." \
        cpe="cpe:/a:redhat:openshift:1.27::el10" \
        com.redhat.component="openshift-golang-builder-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Security" \
        release="202611270924.p2.g6ba2d76.assembly.stream.el10" \
        io.openshift.build.golang-nvr="golang-1.27.4-3.el10_3" \
        io.openshift.build.commit.id="6ba2d76d4dafdab787107644981116d942239ed6" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/6ba2d76d4dafdab787107644981116d942239ed6" \
        io.openshift.tags="Empty"


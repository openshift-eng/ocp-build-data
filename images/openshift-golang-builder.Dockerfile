FROM ubi7:7-released

ARG GOPATH
# This feels a little ugly but it seems to be the simplest way to enable the SCL automatically for docker exec:
ENV container=oci \
    MANPATH=/opt/rh/golang-1.18/root/usr/share/man: \
    X_SCLS=golang-1.18  \
    GOFLAGS='-mod=vendor' \
    LD_LIBRARY_PATH=/opt/rh/golang-1.18/root/usr/lib64 \
    PATH=/opt/rh/golang-1.18/root/usr/bin:/opt/rh/golang-1.18/root/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GOPATH=${GOPATH:-/go} \
    GOMAXPROCS=8 \
    PKG_CONFIG_PATH=/opt/rh/golang-1.18/root/usr/lib64/pkgconfig

RUN mkdir -p /go/src/

RUN yum install -y --setopt=skip_missing_names_on_install=False \
    bc file findutils gpgme git hostname lsof make socat tar tree util-linux wget which zip \
    'golang-*1.18*' goversioninfo openssl openssl-devel systemd-devel gpgme-devel libassuan-devel
RUN yum clean all

LABEL \
        io.k8s.description="This is a golang builder image for building OpenShift Container Platform components." \
        summary="This is a golang builder image for building OpenShift Container Platform components." \
        io.k8s.display-name="golang-builder" \
        com.redhat.component="openshift-golang-builder-container" \
        maintainer="OpenShift ART <aos-team-art@redhat.com>" \
        name="openshift/golang-builder" \
        io.openshift.tags="openshift"

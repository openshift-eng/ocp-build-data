FROM openshift/ose-base:ubi8

ENV SUMMARY="RHEL8 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=/go \
    VERSION="1.14"

ENV SOURCE_GIT_COMMIT= \
    OS_GIT_COMMIT= \
    SOURCE_GIT_URL= \
    SOURCE_GIT_TAG= 

LABEL summary="$SUMMARY" \
      description="$SUMMARY" \
      io.k8s.description="$SUMMARY" \
      io.k8s.display-name="Go Builder $VERSION" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
      version="$VERSION"

RUN yum install -y --setopt=tsflags=nodocs \
    bc diffutils file findutils gpgme git hostname lsof make rsync socat tar tree util-linux wget which zip \
    "go-toolset-$VERSION.*" goversioninfo openssl openssl-devel systemd-devel gpgme-devel libassuan-devel && \
    mkdir -p /go/src && \
    yum clean all -y

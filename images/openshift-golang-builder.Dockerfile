FROM openshift/ose-base:ubi8

ENV SUMMARY="RHEL8 based Go builder image for OpenShift ART" \
    VERSION="1.13"

LABEL summary="$SUMMARY" \
      description="$SUMMARY" \
      io.k8s.description="$SUMMARY" \
      io.k8s.display-name="Go Builder $VERSION" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
      version="$VERSION"

RUN yum install -y --setopt=tsflags=nodocs "golang-$VERSION.*" && \
    yum clean all -y

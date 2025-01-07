# This is a base image for supporting a python app that runs on it.
# The same Dockerfile should serve for most versions of python.
FROM ubi8/python-36:1-114.1599745041

# Start Konflux-specific steps
RUN mkdir -p /tmp/yum_temp; mv /etc/yum.repos.d/*.repo /tmp/yum_temp/ || true
COPY .oit/unsigned.repo /etc/yum.repos.d/
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem /tmp
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202501072046.p0.gf89f57f.assembly.stream.el8 BUILD_VERSION=v4.6.0 OS_GIT_MAJOR=4 OS_GIT_MINOR=6 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=4.6.0-202501072046.p0.gf89f57f.assembly.stream.el8 SOURCE_GIT_TREE_STATE=clean __doozer_group=openshift-4.6 __doozer_key=openshift-base-python __doozer_uuid_tag=base-python-v4.6.0-20250107.204624 __doozer_version=v4.6.0 
ENV __doozer=merge OS_GIT_COMMIT=f89f57f OS_GIT_VERSION=4.6.0-202501072046.p0.gf89f57f.assembly.stream.el8-f89f57f SOURCE_DATE_EPOCH=1617305004 SOURCE_GIT_COMMIT=f89f57f343df982544b68d47b95bd4416f16e52d SOURCE_GIT_TAG=f89f57f3 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 
# rhscl/python-36-rhel7 from rh-python36-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=67385)
# ubi8/python-36 from python-36-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=69964)

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 1001

# Start Konflux-specific steps
RUN cp /tmp/yum_temp/* /etc/yum.repos.d/ || true
# End Konflux-specific steps

LABEL \
        name="openshift/base-python" \
        com.redhat.component="openshift-base-python-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Unknown" \
        version="v4.6.0" \
        release="202501072046.p0.gf89f57f.assembly.stream.el8" \
        io.openshift.build.commit.id="f89f57f343df982544b68d47b95bd4416f16e52d" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/f89f57f343df982544b68d47b95bd4416f16e52d" \
        io.k8s.description="" \
        io.k8s.display-name="" \
        io.openshift.tags="" \
        description="" \
        summary=""


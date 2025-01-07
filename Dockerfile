# This is a base image for supporting a nodejs app that runs on it.
# The same Dockerfile should serve for most versions of nodejs.
FROM ubi8/nodejs-10:1-108

# Start Konflux-specific steps
RUN mkdir -p /tmp/yum_temp; mv /etc/yum.repos.d/*.repo /tmp/yum_temp/ || true
COPY .oit/unsigned.repo /etc/yum.repos.d/
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem /tmp
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202501072046.p0.gea2ee72.assembly.stream.el8 BUILD_VERSION=v4.6.0 OS_GIT_MAJOR=4 OS_GIT_MINOR=6 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=4.6.0-202501072046.p0.gea2ee72.assembly.stream.el8 SOURCE_GIT_TREE_STATE=clean __doozer_group=openshift-4.6 __doozer_key=openshift-base-nodejs-runtime __doozer_uuid_tag=base-nodejs-runtime-v4.6.0-20250107.204624 __doozer_version=v4.6.0 
ENV __doozer=merge OS_GIT_COMMIT=ea2ee72 OS_GIT_VERSION=4.6.0-202501072046.p0.gea2ee72.assembly.stream.el8-ea2ee72 SOURCE_DATE_EPOCH=1617304586 SOURCE_GIT_COMMIT=ea2ee72fd27f6fc67deb6335e39596fa47c0f8da SOURCE_GIT_TAG=ea2ee72f SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 
# rhscl/nodejs-6-rhel7 from rh-nodejs6-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=67372)
# rhscl/nodejs-10-rhel7 from rh-nodejs10-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=70335)
# ubi8/nodejs from from nodejs-10-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=69969)

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 1001

# Start Konflux-specific steps
RUN cp /tmp/yum_temp/* /etc/yum.repos.d/ || true
# End Konflux-specific steps

LABEL \
        name="openshift/base-nodejs-runtime" \
        com.redhat.component="openshift-base-nodejs-runtime-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Unknown" \
        version="v4.6.0" \
        release="202501072046.p0.gea2ee72.assembly.stream.el8" \
        io.openshift.build.commit.id="ea2ee72fd27f6fc67deb6335e39596fa47c0f8da" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/ea2ee72fd27f6fc67deb6335e39596fa47c0f8da" \
        io.k8s.description="" \
        io.k8s.display-name="" \
        io.openshift.tags="" \
        description="" \
        summary=""


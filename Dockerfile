# This is a base image for supporting a ruby app that runs on it.
# The same Dockerfile should serve for most versions of ruby.
FROM ubi8/ruby-25:1-122

# Start Konflux-specific steps
RUN mkdir -p /tmp/yum_temp; mv /etc/yum.repos.d/*.repo /tmp/yum_temp/ || true
COPY .oit/unsigned.repo /etc/yum.repos.d/
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem /tmp
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202501072046.p0.g24aa6dd.assembly.stream.el8 BUILD_VERSION=v4.6.0 OS_GIT_MAJOR=4 OS_GIT_MINOR=6 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=4.6.0-202501072046.p0.g24aa6dd.assembly.stream.el8 SOURCE_GIT_TREE_STATE=clean __doozer_group=openshift-4.6 __doozer_key=openshift-base-ruby __doozer_uuid_tag=base-ruby-v4.6.0-20250107.204624 __doozer_version=v4.6.0 
ENV __doozer=merge OS_GIT_COMMIT=24aa6dd OS_GIT_VERSION=4.6.0-202501072046.p0.g24aa6dd.assembly.stream.el8-24aa6dd SOURCE_DATE_EPOCH=1617303911 SOURCE_GIT_COMMIT=24aa6dd931eb0c48eadad85cf4e7daf6d7803bde SOURCE_GIT_TAG=24aa6dd9 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 
# rhscl/ruby-25-rhel7 from rh-ruby25-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=66958)
# ubi8/ruby from ruby-25-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=69970)

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 1001

# Start Konflux-specific steps
RUN cp /tmp/yum_temp/* /etc/yum.repos.d/ || true
# End Konflux-specific steps

LABEL \
        name="openshift/base-ruby" \
        com.redhat.component="openshift-base-ruby-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Unknown" \
        version="v4.6.0" \
        release="202501072046.p0.g24aa6dd.assembly.stream.el8" \
        io.openshift.build.commit.id="24aa6dd931eb0c48eadad85cf4e7daf6d7803bde" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/24aa6dd931eb0c48eadad85cf4e7daf6d7803bde" \
        io.k8s.description="" \
        io.k8s.display-name="" \
        io.openshift.tags="" \
        description="" \
        summary=""


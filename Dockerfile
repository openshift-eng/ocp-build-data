FROM quay.io/openshift-release-dev/ocp-v4.0-art-dev-test:openshift-enterprise-base-rhel9-v4.18.0-20241016.134725

# Start Konflux-specific steps
RUN mkdir -p /tmp/yum_temp; mv /etc/yum.repos.d/*.repo /tmp/yum_temp/ || true
COPY .oit/unsigned.repo /etc/yum.repos.d/
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem /tmp
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202410161347.p0.g495d512.assembly.test.el9 BUILD_VERSION=v4.18.0 CI_RPM_SVC=base-4-18-rhel9.ocp.svc OS_GIT_MAJOR=4 OS_GIT_MINOR=18 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=4.18.0-202410161347.p0.g495d512.assembly.test.el9 SOURCE_GIT_TREE_STATE=clean __doozer_group=openshift-4.18 __doozer_key=ci-openshift-base.rhel9 __doozer_uuid_tag=ci-openshift-base-rhel9-v4.18.0-20241016.134725 __doozer_version=v4.18.0 
ENV __doozer=merge OS_GIT_COMMIT=495d512 OS_GIT_VERSION=4.18.0-202410161347.p0.g495d512.assembly.test.el9-495d512 SOURCE_DATE_EPOCH=1729024584 SOURCE_GIT_COMMIT=495d512878d04cf992d5bb88e27bfde1df57e5dd SOURCE_GIT_TAG=openshift-4.0-archived-3590-g495d5128 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 

# Used by builds scripts to detect whether they are running in the context
# of OpenShift CI or elsewhere (e.g. brew).
ENV OPENSHIFT_CI="true"

# Ensure that repo files can be written by non-root users at runtime so that repos
# can be resolved on build farms and written into yum.repos.d.
RUN chmod 777 /etc/yum.repos.d/

# Install the dnf/yum wrapper that will work for CI workloads.
ENV DNF_WRAPPER_DIR=/bin/dnf_wrapper
ADD ci_images/dnf_wrapper.sh /tmp
ADD ci_images/install_dnf_wrapper.sh /tmp
RUN chmod +x /tmp/*.sh && \
    /tmp/install_dnf_wrapper.sh
# Ensure dnf wrapper scripts appear before anything else in the $PATH
ENV PATH=$DNF_WRAPPER_DIR:$PATH
# Add the doozer repos so that someone connected to the VPN can use those
# repositories. The dnf_wrapper will enable these repos if it detects
# it is not running on a build farm.
ADD .oit/unsigned.repo $DNF_WRAPPER_DIR/


# Start Konflux-specific steps
RUN cp /tmp/yum_temp/* /etc/yum.repos.d/ || true
# End Konflux-specific steps

LABEL \
        io.k8s.description="openshift-enterprise-base-rhel9 for Red Hat CI" \
        name="openshift/ci-openshift-base-rhel9" \
        com.redhat.component="ci-openshift-base-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Unknown" \
        version="v4.18.0" \
        release="202410161347.p0.g495d512.assembly.test.el9" \
        io.openshift.build.commit.id="495d512878d04cf992d5bb88e27bfde1df57e5dd" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/495d512878d04cf992d5bb88e27bfde1df57e5dd"


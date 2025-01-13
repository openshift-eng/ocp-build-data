FROM replaced_by_doozer

# Used by builds scripts to detect whether they are running in the context
# of OpenShift CI or elsewhere (e.g. brew).
ENV OPENSHIFT_CI="true"

# Turn off information for CI environment. This is usually just noise for upstream
# engineers and can complicate debug. When issues arise, have repos export
# GO_COMPLIANCE_INFO=1 or GO_COMPLIANCE_DEBUG=1 before running go.
ENV GO_COMPLIANCE_INFO=0

ENV GOARM=5 \
    LOGNAME=deadbeef \
    GOCACHE=/go/.cache \
    GOPATH=/go \
    LOGNAME=deadbeef
ENV PATH=$PATH:$GOPATH/bin

# make go related directories writeable since builds in CI will run as non-root.
RUN mkdir -p $GOPATH && \
    chmod g+xw -R $GOPATH && \
    chmod g+xw -R $(go env GOROOT)

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin

# Ensure that repo files can be written by non-root users at runtime so that repos
# can be resolved on build farms and written into yum.repos.d.
RUN chmod 777 /etc/yum.repos.d/

# Install the dnf/yum wrapper that will work for CI workloads.
ENV DNF_WRAPPER_DIR=/bin/dnf_wrapper

# Directories relevant to dnf_wrapper.sh
ENV ART_REPOS_DIR_CI="/etc/yum.repos.art/ci"
ENV ART_REPOS_DIR_LOCALDEV="/etc/yum.repos.art/localdev"

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

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin

# These services run on the build farms and serve RPMs to CI workloads.
# This environment variable is used by dnf_wrapper.sh to know which service
# to acquire repo information from.
ENV CI_RPM_SVC=base-MAJOR-MINOR-rhelX.ocp.svc

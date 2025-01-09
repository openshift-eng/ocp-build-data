FROM replaced_by_doozer

# Used by builds scripts to detect whether they are running in the context
# of OpenShift CI or elsewhere (e.g. brew).
ENV OPENSHIFT_CI="true"

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


FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.22.5-202407301806.g4c8b32d.el9
USER root

RUN dnf -y install python3 jq gettext python3-pyyaml \
    && dnf clean all

# Install yq using wget and make it executable
RUN url="$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/mikefarah/yq/releases/latest)" \
    && YQ_VER="${url##*/}" \
    && YQ_URL=https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_$(go env GOARCH) \
    && wget -O /usr/bin/yq $YQ_URL \
    && chmod +x /usr/bin/yq

# Manually download and install OpenShift client (oc)
ENV OC_VERSION=4.17.0
ENV OC_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux.tar.gz

RUN wget ${OC_URL} -O openshift-client-linux.tar.gz && \
    tar -zxvf openshift-client-linux.tar.gz && \
    cp oc /usr/local/bin/ && \
    cp kubectl /usr/local/bin/ && \
    rm -rf openshift-client-linux.tar.gz oc kubectl

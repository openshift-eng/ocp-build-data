FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.19.10-202307181602.el8.g71f6585
USER root

RUN yum -y install python3 jq gettext python3-pyyaml && \
    yum clean all

# Install yq using wget and make it executable
RUN YQ_VER=4.26.1 \
    && YQ_URL=https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_$(go env GOARCH) \
    && wget -O /usr/bin/yq $YQ_URL \
    && chmod +x /usr/bin/yq

# Manually download and install OpenShift client (oc)
ENV OC_VERSION=4.13.4
ENV OC_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux.tar.gz

RUN wget ${OC_URL} -O openshift-client-linux.tar.gz && \
    tar -zxvf openshift-client-linux.tar.gz && \
    cp oc /usr/local/bin/ && \
    cp kubectl /usr/local/bin/ && \
    rm -rf openshift-client-linux.tar.gz oc kubectl

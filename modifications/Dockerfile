FROM registry-proxy.engineering.redhat.com/rh-osbs/openshift-golang-builder:v1.19.10-202306161424.el9.g372eaca

USER root

# Unset GOFLAGS
ENV GOFLAGS=""

# Set up a local module proxy
RUN go env -w GOPRIVATE=*
RUN go env -w GOPROXY=file:///go/mod
RUN export GOPROXY=direct

RUN yum -y install python3 && \
    python3 -m ensurepip && \
    pip3 install --upgrade pip && \
    pip3 install PyYAML && \
    yum clean all

# Install yq using wget and make it executable
RUN YQ_VER=4.26.1 \
    && YQ_URL=https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_$(go env GOARCH) \
    && wget -O /usr/bin/yq $YQ_URL \
    && chmod +x /usr/bin/yq

# Install jq from source
RUN wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x ./jq && \
    cp jq /usr/bin

# Manually download and install OpenShift client (oc)
ENV OC_VERSION=4.13.4
ENV OC_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux.tar.gz

RUN wget ${OC_URL} -O openshift-client-linux.tar.gz && \
    tar -zxvf openshift-client-linux.tar.gz && \
    cp oc /usr/local/bin/ && \
    cp kubectl /usr/local/bin/ && \
    rm -rf openshift-client-linux.tar.gz oc kubectl

# Make sure to install git before cloning the repository
RUN yum -y install epel-release && \
    yum -y install git && \
    yum clean all

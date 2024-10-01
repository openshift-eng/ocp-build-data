FROM openshift/ci-openshift-golang-builder-latest-rhel8:v4.18.0-202409301642.p0.g3e99cf1.assembly.test.el8

# Start Konflux-specific steps
RUN mkdir -p /tmp/yum_temp; mv /etc/yum.repos.d/*.repo /tmp/yum_temp/ || true
COPY .oit/unsigned.repo /etc/yum.repos.d/
ADD https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem /tmp
# End Konflux-specific steps
ENV __doozer=update BUILD_RELEASE=202410011846.p0.g76e0373.assembly.test.el8 BUILD_VERSION=v4.18.0 CI_RPM_SVC=base-4-18-rhel8.ocp.svc OS_GIT_MAJOR=4 OS_GIT_MINOR=18 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=4.18.0-202410011846.p0.g76e0373.assembly.test.el8 SOURCE_GIT_TREE_STATE=clean __doozer_group=openshift-4.18 __doozer_key=ci-openshift-build-root-latest.rhel8 __doozer_uuid_tag=ci-openshift-build-root-latest-rhel8-v4.18.0-20241001.184614 __doozer_version=v4.18.0 
ENV __doozer=merge OS_GIT_COMMIT=76e0373 OS_GIT_VERSION=4.18.0-202410011846.p0.g76e0373.assembly.test.el8-76e0373 SOURCE_DATE_EPOCH=1727808221 SOURCE_GIT_COMMIT=76e037380bb75d440030c3feab30d143eab52285 SOURCE_GIT_TAG=openshift-4.0-archived-3543-g76e03738 SOURCE_GIT_URL=https://github.com/openshift-eng/ocp-build-data 

# Used by builds scripts to detect whether they are running in the context
# of OpenShift CI or elsewhere (e.g. brew).
ENV OPENSHIFT_CI="true"

ENV GO_COMPLIANCE_POLICY=exempt_all

# Install, matching upstream k8s, protobuf-3.x, see:
# https://github.com/kubernetes/kubernetes/blob/master/hack/lib/protoc.sh
# and etcd, see:
# https://github.com/kubernetes/kubernetes/blob/master/hack/lib/etcd.sh
# for CI only testing.
ENV PATH=/opt/google/protobuf/bin:$PATH

# Note that GHPROXY requests will only pass certificate checks in brew if
# SSL_CERT_FILE=/tmp/tls-ca-bundle.pem (the CA injected by brew which
# trusts the RH certificate used by ocp-artifacts)
ENV GHPROXY_PREFIX="https://ocp-artifacts.engineering.redhat.com/github"

ADD ci_images/install_protoc.sh /tmp
ADD ci_images/install_etcd.sh /tmp

RUN set -euxo pipefail && \
    chmod +x /tmp/*.sh && \
    export SSL_CERT_FILE=`test -f /tmp/tls-ca-bundle.pem && echo /tmp/tls-ca-bundle.pem || echo /tmp/Current-IT-Root-CAs.pem` && cat $SSL_CERT_FILE && \
    /tmp/install_protoc.sh "23.4" && \
    /tmp/install_etcd.sh "3.5.10"

RUN INSTALL_PKGS="glibc libatomic libsemanage annobin go-srpm-macros libstdc++ llvm-libs qt5-srpm-macros redhat-rpm-config bc procps-ng util-linux bind-utils bsdtar createrepo_c device-mapper device-mapper-persistent-data e2fsprogs ethtool file findutils gcc git glib2-devel gpgme gpgme-devel hostname iptables jq krb5-devel libassuan libassuan-devel libseccomp-devel lsof make nmap-ncat openssl rsync socat systemd-devel tar tree wget which xfsprogs zip goversioninfo gettext python3 iproute rpm-build" && \
    dnf install -y --nobest $INSTALL_PKGS && \
    dnf clean all && \
    touch /os-build-image && \
    git config --system user.name origin-release-container && \
    git config --system user.email origin-release@redhat.com

# Notes:
# - brew will not be able to access go modules outside RH, setting GOPROXY allows them to be sourced from ocp-artifacts
# - brew will not be able to connect to https://sum.golang.org/ . GOSUMDB='off' disables this check.
# - brew temporarily injects a trust store at /tmp/tls-ca-bundle.pem. Setting SSL_CERT_FILE allows go install to use it.
#   this is important because the system trust store does not trust Red Hat IT certificates.
RUN export GOPROXY="https://ocp-artifacts.engineering.redhat.com/goproxy/" && \
    export GOSUMDB='off' && \
    export GOFLAGS='' && export GO111MODULE=on && \
    export SSL_CERT_FILE=`test -f /tmp/tls-ca-bundle.pem && echo /tmp/tls-ca-bundle.pem || echo /tmp/Current-IT-Root-CAs.pem` && cat $SSL_CERT_FILE && \
    go install golang.org/x/tools/cmd/cover@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/tools/godep@latest && \
    go install golang.org/x/lint/golint@latest && \
    go install gotest.tools/gotestsum@latest && \
    go install github.com/openshift/release/tools/gotest2junit@latest && \
    go install github.com/openshift/imagebuilder/cmd/imagebuilder@latest && \
    mv $GOPATH/bin/* /usr/bin/ && \
    rm -rf $GOPATH/* $GOPATH/.cache && \
    mkdir $GOPATH/bin && \
    mkdir -p /go/src/github.com/openshift/origin && \
    ln -s /usr/bin/imagebuilder $GOPATH/bin/imagebuilder && \
    ln -s /usr/bin/goimports $GOPATH/bin/goimports && \
    curl --fail -L -k $GHPROXY_PREFIX/golang/dep/releases/download/v0.5.4/dep-linux-amd64 > /usr/bin/dep && \
    chmod +x /usr/bin/dep

# make go related directories writeable since builds in CI will run as non-root. go install
# may have created new directories.
RUN mkdir -p $GOPATH && \
    chmod g+xw -R $GOPATH && \
    chmod g+xw -R $(go env GOROOT)

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin

# Start Konflux-specific steps
RUN cp /tmp/yum_temp/* /etc/yum.repos.d/ || true
# End Konflux-specific steps

LABEL \
        io.k8s.description="golang 1.22 build-root image for Red Hat CI" \
        name="openshift/ci-openshift-build-root-latest-rhel8" \
        com.redhat.component="ci-openshift-build-root-latest-container" \
        io.openshift.maintainer.project="OCPBUGS" \
        io.openshift.maintainer.component="Unknown" \
        version="v4.18.0" \
        release="202410011846.p0.g76e0373.assembly.test.el8" \
        io.openshift.build.commit.id="76e037380bb75d440030c3feab30d143eab52285" \
        io.openshift.build.source-location="https://github.com/openshift-eng/ocp-build-data" \
        io.openshift.build.commit.url="https://github.com/openshift-eng/ocp-build-data/commit/76e037380bb75d440030c3feab30d143eab52285"

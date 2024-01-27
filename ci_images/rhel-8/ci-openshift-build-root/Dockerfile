FROM replaced_by_doozer

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
ENV GHPROXY_PREFIX="https://ocp-artifacts.hosts.prod.psi.rdu2.redhat.com/github"

ADD ci_images/install_protoc.sh /tmp
ADD ci_images/install_etcd.sh /tmp

RUN set -euxo pipefail && \
    chmod +x /tmp/*.sh && \
    export SSL_CERT_FILE=/tmp/tls-ca-bundle.pem && \
    /tmp/install_protoc.sh "23.4" && \
    /tmp/install_etcd.sh "3.5.10"

RUN CI_PINNED_GIT_VERSION="git-2.31.1" && \
    echo "Uninstalling any pre-existing git to ensure that we install ${CI_PINNED_GIT_VERSION}" && yum remove -y git || true && \
    INSTALL_PKGS="glibc libatomic libsemanage annobin go-srpm-macros libstdc++ llvm-libs qt5-srpm-macros redhat-rpm-config bc procps-ng util-linux bind-utils bsdtar createrepo_c device-mapper device-mapper-persistent-data e2fsprogs ethtool file findutils gcc ${CI_PINNED_GIT_VERSION} glib2-devel gpgme gpgme-devel hostname iptables jq krb5-devel libassuan libassuan-devel libseccomp-devel lsof make nmap-ncat openssl rsync socat systemd-devel tar tree wget which xfsprogs zip goversioninfo gettext python3 iproute rpm-build" && \
    yum install -y $INSTALL_PKGS && \
    yum clean all && \
    touch /os-build-image && \
    git config --system user.name origin-release-container && \
    git config --system user.email origin-release@redhat.com

# Notes:
# - brew will not be able to access go modules outside RH, setting GOPROXY allows them to be sourced from ocp-artifacts
# - brew will not be able to connect to https://sum.golang.org/ . GOSUMDB='off' disables this check.
# - brew temporarily injects a trust store at /tmp/tls-ca-bundle.pem. Setting SSL_CERT_FILE allows go install to use it.
#   this is important because the system trust store does not trust Red Hat IT certificates.
RUN export GOPROXY="https://ocp-artifacts.hosts.prod.psi.rdu2.redhat.com:9443" && \
    export GOSUMDB='off' && \
    export GOFLAGS='' && export GO111MODULE=on && \
    export SSL_CERT_FILE=/tmp/tls-ca-bundle.pem && \
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

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin

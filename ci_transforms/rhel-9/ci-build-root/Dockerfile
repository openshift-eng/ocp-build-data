FROM replaced-by-buildconfig
# Serves as a standard build environment for OpenShift builds. It is based on the
# ART golang builder and has packages layered on top of support CI only use cases
# (e.g. compiling test cases) that simply don't occur downstream.
# Used as a template for 'images:streams gen-buildconfigs'

# Install, matching upstream k8s, protobuf-3.x, see:
# https://github.com/kubernetes/kubernetes/blob/master/hack/lib/protoc.sh
# and etcd, see:
# https://github.com/kubernetes/kubernetes/blob/master/hack/lib/etcd.sh
# for CI only testing.
ENV PATH=/opt/google/protobuf/bin:$PATH
RUN set -euxo pipefail && \
    f=$( mktemp ) && \
    curl --fail -L https://github.com/protocolbuffers/protobuf/releases/download/v3.19.4/protoc-3.19.4-linux-x86_64.zip > "${f}" && \
    mkdir -p /opt/google/protobuf && \
    unzip "${f}" -d /opt/google/protobuf && \
    curl --fail -L https://github.com/coreos/etcd/releases/download/v3.5.7/etcd-v3.5.7-linux-amd64.tar.gz | tar -f - -xz --no-same-owner -C /usr/local/bin --strip-components=1 etcd-v3.5.7-linux-amd64/etcd

# Install common CI tools and epel for other devel packages
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    INSTALL_PKGS="bc procps-ng util-linux bind-utils bsdtar createrepo_c device-mapper device-mapper-persistent-data e2fsprogs ethtool file findutils gcc git glib2-devel gpgme gpgme-devel hostname iptables jq krb5-devel libassuan libassuan-devel libseccomp-devel lsof make nmap-ncat openssl rsync socat systemd-devel tar tree wget which xfsprogs zip goversioninfo gettext python3 iproute" && \
    yum install -y $INSTALL_PKGS && \
    yum clean all && \
    touch /os-build-image && \
    git config --system user.name origin-release-container && \
    git config --system user.email origin-release@redhat.com

# Install common go tools upstream devs are expecting in CI.
# Pure cargo culting from https://github.com/openshift/release/blob/51d92eb6a6d730e932a5daf68829ca7936739904/projects/origin-release/golang-1.13/Dockerfile#L41
# Clear GOFLAGS temporarily for 1.12  bug:https://github.com/golang/go/issues/32502
RUN GOFLAGS='' GO111MODULE=on go install golang.org/x/tools/cmd/cover@latest && \
    GOFLAGS='' GO111MODULE=on go install golang.org/x/tools/cmd/goimports@latest && \
    GOFLAGS='' GO111MODULE=on go install github.com/tools/godep@latest && \
    GOFLAGS='' GO111MODULE=on go install golang.org/x/lint/golint@latest && \
    GOFLAGS='' GO111MODULE=on go install gotest.tools/gotestsum@latest && \
    GOFLAGS='' GO111MODULE=on go install github.com/openshift/release/tools/gotest2junit@latest && \
    GOFLAGS='' GO111MODULE=on go install github.com/openshift/imagebuilder/cmd/imagebuilder@latest && \
    mv $GOPATH/bin/* /usr/bin/ && \
    rm -rf $GOPATH/* $GOPATH/.cache && \
    mkdir $GOPATH/bin && \
    mkdir -p /go/src/github.com/openshift/origin && \
    ln -s /usr/bin/imagebuilder $GOPATH/bin/imagebuilder && \
    ln -s /usr/bin/goimports $GOPATH/bin/goimports && \
    curl --fail -L https://github.com/golang/dep/releases/download/v0.5.4/dep-linux-amd64 > /usr/bin/dep && \
    chmod +x /usr/bin/dep

# make go related directories writeable since builds in CI will run as non-root.
RUN mkdir -p $GOPATH && \
    chmod g+xw -R $GOPATH && \
    chmod g+xw -R $(go env GOROOT)

# Assert packages in separate RUN block so we are sure env variables are set up correctly
RUN set -euxo pipefail && \
    command -v protoc && protoc --version && [ "$( protoc --version )" = "libprotoc 3.19.4" ] && \
    command -v etcd && etcd --version && [ "$( etcd --version | head -n1 )" = "etcd Version: 3.5.7" ]

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin

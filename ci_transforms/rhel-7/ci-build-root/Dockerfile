FROM replaced-by-buildconfig
# Serves as a standard build environment for OpenShift builds. It is ultimately based on the
# ART golang builder and has packages layered on top of support CI only use cases
# (e.g. compiling test cases) that simply don't occur downstream.
# Used as a template for 'images:streams gen-buildconfigs'

# Turn off information for CI environment. This is usually just noise for upstream
# engineers and can complicate debug. When issues arise, have repos export
# GO_COMPLIANCE_INFO=1 or GO_COMPLIANCE_DEBUG=1 before running go.
ENV GO_COMPLIANCE_INFO=0

ENV OPENSHIFT_CI=true

# Install common CI tools and epel for packages like tito.
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    INSTALL_PKGS="bc bind-utils bsdtar bzr ceph-common createrepo device-mapper device-mapper-persistent-data e2fsprogs ethtool file findutils gcc git glibc-static glib2-devel gpgme gpgme-devel hostname iptables jq krb5-devel libassuan libassuan-devel libseccomp-devel libvirt-devel lsof make mercurial nmap-ncat openssl protobuf-compiler protobuf-devel rsync socat systemd-devel sysvinit-tools tar tito tree util-linux wget which xfsprogs zip goversioninfo gettext" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    touch /os-build-image && \
    git config --system user.name origin-release-container && \
    git config --system user.email origin-release@redhat.com

# Install common go tools upstream devs are expecting in CI.
# Pure cargo culting from https://github.com/openshift/release/blob/51d92eb6a6d730e932a5daf68829ca7936739904/projects/origin-release/golang-1.13/Dockerfile#L41
RUN GOFLAGS='' go install golang.org/x/tools/cmd/cover@latest && \
    GOFLAGS='' go install golang.org/x/tools/cmd/goimports@latest && \
    GOFLAGS='' go install github.com/tools/godep@latest && \
    GOFLAGS='' go install golang.org/x/lint/golint@latest && \
    GOFLAGS='' go install gotest.tools/gotestsum@latest && \
    GOFLAGS='' go install github.com/openshift/release/tools/gotest2junit@latest && \
    GOFLAGS='' go install github.com/openshift/imagebuilder/cmd/imagebuilder@latest && \
    mv $GOPATH/bin/* /usr/bin/ && \
    rm -rf $GOPATH/* $GOPATH/.cache && \
    mkdir $GOPATH/bin && \
    mkdir -p /go/src/github.com/openshift/origin && \
    ln -s /usr/bin/imagebuilder $GOPATH/bin/imagebuilder && \
    ln -s /usr/bin/goimports $GOPATH/bin/goimports && \
    curl -L https://github.com/golang/dep/releases/download/v0.5.4/dep-linux-amd64 > /usr/bin/dep && \
    chmod +x /usr/bin/dep

RUN chmod g+xw -R $GOPATH && \
    chmod g+xw -R $(go env GOROOT)

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin

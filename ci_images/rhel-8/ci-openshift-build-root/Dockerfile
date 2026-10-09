FROM replaced_by_doozer

# Used by builds scripts to detect whether they are running in the context
# of OpenShift CI or elsewhere (e.g. brew).
ENV OPENSHIFT_CI="true"

ENV GO_COMPLIANCE_POLICY=exempt_all

# Turn off information for CI environment. This is usually just noise for upstream
# engineers and can complicate debug. When issues arise, have repos export
# GO_COMPLIANCE_INFO=1 or GO_COMPLIANCE_DEBUG=1 before running go.
ENV GO_COMPLIANCE_INFO=0

# Install, matching upstream k8s, protobuf-3.x, see:
# https://github.com/kubernetes/kubernetes/blob/master/hack/lib/protoc.sh
# and etcd, see:
# https://github.com/kubernetes/kubernetes/blob/master/hack/lib/etcd.sh
# for CI only testing.
ENV PATH=/opt/google/protobuf/bin:$PATH

ADD ci_images/install_protoc.sh /tmp
ADD ci_images/install_etcd.sh /tmp

RUN set -euxo pipefail && \
    chmod +x /tmp/*.sh && \
    /tmp/install_protoc.sh "23.4" && \
    /tmp/install_etcd.sh "3.6.8"

RUN INSTALL_PKGS="glibc libatomic libsemanage annobin go-srpm-macros libstdc++ llvm-libs qt5-srpm-macros redhat-rpm-config bc procps-ng util-linux bind-utils bsdtar createrepo_c device-mapper device-mapper-persistent-data e2fsprogs ethtool file findutils gcc git glib2-devel gpgme gpgme-devel hostname iptables jq krb5-devel libassuan libassuan-devel libseccomp-devel lsof make nmap-ncat openssl rsync socat systemd-devel tar tree wget which xfsprogs zip goversioninfo gettext python3 iproute rpm-build" && \
    dnf install -y $INSTALL_PKGS && \
    dnf clean all && \
    touch /os-build-image && \
    git config --system user.name origin-release-container && \
    git config --system user.email origin-release@redhat.com

RUN export GOFLAGS='' && export GO111MODULE=on && \
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
    curl --fail -L "https://github.com/golang/dep/releases/download/v0.5.4/dep-linux-amd64" > /usr/bin/dep && \
    chmod +x /usr/bin/dep

# make go related directories writeable since builds in CI will run as non-root. go install
# may have created new directories.
# Resolve GOROOT before the chmod: when GOFIPS140 defaults to "certified"
# (e.g. golang-1.26.7-2.el9_8), any go invocation extracts the FIPS module
# snapshot into $GOPATH/pkg/mod, which must also be made group-writable.
RUN GOROOT_DIR=$(go env GOROOT) && \
    mkdir -p $GOPATH && \
    chmod g+xw -R $GOPATH $GOROOT_DIR

# Some image building tools don't create a missing WORKDIR
RUN mkdir -p /go/src/github.com/openshift/origin
WORKDIR /go/src/github.com/openshift/origin

# These services run on the build farms and serve RPMs to CI workloads.
# This environment variable is used by dnf_wrapper.sh to know which service
# to acquire repo information from.
ENV CI_RPM_SVC=base-MAJOR-MINOR-rhelX.ocp.svc

FROM registry.redhat.io/ubi8:latest

ARG GOPATH
ENV SUMMARY="RHEL8 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=${GOPATH:-/go} \
    GOMAXPROCS=8 \
    VERSION="1.21" \
    GODEBUG="disablethp=1"

LABEL summary="$SUMMARY" \
      description="$SUMMARY" \
      io.k8s.description="$SUMMARY" \
      io.k8s.display-name="Go Builder $VERSION" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
      version="$VERSION"

RUN dnf update -y && \
    dnf install -y --nodocs \
        bc \
        diffutils \
        dos2unix \
        file \
        findutils \
        git \
        goversioninfo \
        gpgme \
        gpgme-devel \
        hostname \
        libassuan-devel \
        libtool \
        lsof \
        make \
        openssl \
        openssl-devel \
        patch \
        python3 \
        rsync \
        socat \
        systemd-devel \
        tar \
        tree \
        util-linux \
        wget \
        which \
        xz \
        zip && \
    dnf install -y "golang-*$VERSION*" && \
    mkdir -p /go/src
# provide a cross-compiler for windows/mac binaries (amd64 only)
COPY cross.tar.gz .
RUN [ $(go env GOARCH) != "amd64" ] || (\
    # only install cross-compiler dependencies on amd64
    yum install -y --setopt=tsflags=nodocs \
    # Required packages for mac cross-compilation
    llvm-toolset cmake3 gcc-c++ libxml2-devel \
    # Required packages for windows cross-compilation
    glibc mingw64-gcc && \
    # compile macos cross-compilers
    tar zfx cross.tar.gz && \
    export TP_OSXCROSS_DEV=$(pwd)/cross/deps && \
    pushd cross/osxcross && \
    UNATTENDED=yes ./build.sh && \
    popd && \
    cp -avr cross/osxcross/target/bin/* /usr/local/bin/ && \
    cp -avr cross/osxcross/target/lib/* /usr/local/lib64/ && \
    cp -avr cross/osxcross/target/SDK /usr/local/SDK && \
    echo /usr/local/lib64 > /etc/ld.so.conf.d/local.conf && \
    /sbin/ldconfig && \
    rm -rf cross)

# above is conditional; clean up unconditionally
RUN rm -f cross.tar.gz && yum clean all -y

# FOD wrapper modification
COPY go_wrapper.sh /tmp/go_wrapper.sh
RUN GO_BIN_PATH=$(which go) && mv $GO_BIN_PATH $GO_BIN_PATH.real && mv /tmp/go_wrapper.sh $GO_BIN_PATH && chmod +x $GO_BIN_PATH

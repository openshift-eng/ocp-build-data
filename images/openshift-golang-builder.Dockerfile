FROM registry.redhat.io/ubi9:latest

ARG GOPATH
ENV SUMMARY="RHEL9 based Go builder image for OpenShift ART" \
    container=oci \
    GOFLAGS='-mod=vendor' \
    GOPATH=${GOPATH:-/go} \
    GOMAXPROCS=8 \
    VERSION="1.20"

LABEL summary="$SUMMARY" \
      description="$SUMMARY" \
      io.k8s.description="$SUMMARY" \
      io.k8s.display-name="Go Builder $VERSION" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
      version="$VERSION"

RUN yum update -y && \
    yum install -y --setopt=tsflags=nodocs \
        bc \
        diffutils \
        dos2unix \
        file \
        findutils \
        git \
        "golang-*$VERSION*" \
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

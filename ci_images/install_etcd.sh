#!/bin/sh
set -euxo pipefail

VER="$1"

echo "Building for arch $(arch)"

etcd_arch_suffix=$(case $(arch) in "x86_64") echo "amd64";;        "arm"*) echo "arm64";;      "aarch"*) echo "arm64";;       "ppc"*) echo "ppc64le";;      "s390"*) echo "s390x";;   "*") echo "UNKNOWN_ARCH";;      esac) && \

curl --fail -k -L -v $GHPROXY_PREFIX/coreos/etcd/releases/download/v${VER}/etcd-v${VER}-linux-${etcd_arch_suffix}.tar.gz | tar -f - -xz --no-same-owner -C /usr/local/bin --strip-components=1 etcd-v${VER}-linux-${etcd_arch_suffix}/etcd


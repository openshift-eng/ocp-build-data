#!/bin/sh
set -euxo pipefail

VER="$1"

echo "Building for arch $(arch)"

f=$( mktemp )
protoc_arch_suffix=$(case $(arch) in "x86_64") echo "x86_64";;        "arm"*) echo "aarch_64";;      "aarch"*) echo "aarch_64";;       "ppc"*) echo "ppcle_64";;      "s390"*) echo "s390_64";;   "*") echo "UNKNOWN_ARCH";;      esac)

curl --fail -k -v -L $GHPROXY_PREFIX/protocolbuffers/protobuf/releases/download/v${VER}/protoc-${VER}-linux-${protoc_arch_suffix}.zip > "${f}"

mkdir -p /opt/google/protobuf

unzip "${f}" -d /opt/google/protobuf

#!/usr/bin/env bash

set -euo pipefail

# DEFAULT_SDK_SHA256 is from sha256sum of MacOSX10.15.sdk.tar.xz extracted
# from the published legacy cross.tar.gz. DEFAULT_SOURCE_DATE_EPOCH is a fixed
# 2020-08-27 16:00:00 UTC normalization time based on that archive's build date;
# it is intentionally stable, not an exact timestamp recovered from its metadata.
readonly DEFAULT_SDK_SHA256="05c98ed96b677dfba862356cba317cdcb7bfdff973150a60e0d1027da705c4cc"
readonly DEFAULT_SOURCE_DATE_EPOCH="1598544000"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly SCRIPT_DIR

# These revisions reproduce the source versions in the legacy 2020 bundle.
# Override any REF variable in the environment to intentionally update a source.
OSXCROSS_REF="${OSXCROSS_REF:-cc1823a726bb4ca8cd76f8702180d9f1de4a4748}"
XAR_REF="${XAR_REF:-2b9a4ab7003f1db8c54da4fea55fcbb424fdecb0}"
APPLE_LIBTAPI_REF="${APPLE_LIBTAPI_REF:-86f43cdb62a3ceb39f3ee6e4568eded67a4912e8}"
CCTOOLS_PORT_REF="${CCTOOLS_PORT_REF:-b7230b3319891168397eae1c8f23670f48a6d1c1}"

sdk=""
sdk_sha256="${SDK_SHA256:-$DEFAULT_SDK_SHA256}"
output="cross.tar.gz"
cache_dir="${CROSS_SOURCE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/openshift-golang-builder-cross}"
source_date_epoch="${SOURCE_DATE_EPOCH:-$DEFAULT_SOURCE_DATE_EPOCH}"

usage() {
  cat <<'EOF'
Usage: build-cross-tarball.sh --sdk PATH [options]

Create the cross.tar.gz source bundle consumed by openshift-golang-builder.

Options:
  --sdk PATH          MacOSX10.15.sdk.tar.xz input (required)
  --sdk-sha256 HASH   Expected SDK SHA-256 (default: legacy bundle checksum)
  --output PATH       Output archive (default: ./cross.tar.gz)
  --cache-dir PATH    Download cache directory
  -h, --help          Show this help

Source revisions can be changed with OSXCROSS_REF, APPLE_LIBTAPI_REF,
CCTOOLS_PORT_REF, and XAR_REF. SOURCE_DATE_EPOCH controls the normalized
archive timestamp.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    --sdk)
      (($# >= 2)) || die "--sdk requires a path"
      sdk=$2
      shift 2
      ;;
    --sdk-sha256)
      (($# >= 2)) || die "--sdk-sha256 requires a hash"
      sdk_sha256=$2
      shift 2
      ;;
    --output)
      (($# >= 2)) || die "--output requires a path"
      output=$2
      shift 2
      ;;
    --cache-dir)
      (($# >= 2)) || die "--cache-dir requires a path"
      cache_dir=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$sdk" ]] || die "--sdk is required"
[[ -f "$sdk" ]] || die "SDK not found: $sdk"
[[ "$sdk_sha256" =~ ^[0-9a-fA-F]{64}$ ]] || die "invalid SDK SHA-256: $sdk_sha256"
[[ "$source_date_epoch" =~ ^[0-9]+$ ]] || die "SOURCE_DATE_EPOCH must be an integer"

for command in awk curl dirname gzip install mktemp patch sha256sum tar; do
  command -v "$command" >/dev/null || die "required command not found: $command"
done

actual_sdk_sha256=$(sha256sum "$sdk" | awk '{print $1}')
[[ "$actual_sdk_sha256" == "${sdk_sha256,,}" ]] ||
  die "SDK SHA-256 is $actual_sdk_sha256, expected ${sdk_sha256,,}"

mkdir -p "$cache_dir" "$(dirname "$output")"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/cross-tarball.XXXXXXXX")
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/cross/deps" "$work_dir/cross/osxcross"

fetch_github_source() {
  local repository=$1
  local ref=$2
  local destination=$3
  local archive_name=${repository//\//-}-${ref//\//-}.tar.gz
  local archive="$cache_dir/$archive_name"
  local temporary="$archive.part"

  if [[ ! -s "$archive" ]]; then
    printf 'Downloading %s at %s\n' "$repository" "$ref"
    curl --fail --location --retry 3 \
      --output "$temporary" \
      "https://github.com/$repository/archive/$ref.tar.gz"
    gzip -t "$temporary"
    mv "$temporary" "$archive"
  fi

  mkdir -p "$destination"
  tar -xzf "$archive" --strip-components=1 -C "$destination"
}

fetch_github_source tpoechtrager/osxcross "$OSXCROSS_REF" "$work_dir/cross/osxcross"
fetch_github_source tpoechtrager/xar "$XAR_REF" "$work_dir/cross/deps/xar"
fetch_github_source tpoechtrager/apple-libtapi "$APPLE_LIBTAPI_REF" "$work_dir/cross/deps/apple-libtapi"
fetch_github_source tpoechtrager/cctools-port "$CCTOOLS_PORT_REF" "$work_dir/cross/deps/cctools-port"

# These public headers use unqualified uint8_t/uint32_t. stdint.h guarantees
# those names in the global namespace; cstdint alone only guarantees std::*.
patch -d "$work_dir/cross/deps/apple-libtapi" -p1 \
  <"$SCRIPT_DIR/apple-libtapi-stdint.patch"

mkdir -p "$work_dir/cross/osxcross/tarballs"
install -m 0644 "$sdk" "$work_dir/cross/osxcross/tarballs/MacOSX10.15.sdk.tar.xz"

cat >"$work_dir/cross/SOURCES" <<EOF
osxcross https://github.com/tpoechtrager/osxcross.git $OSXCROSS_REF
xar https://github.com/tpoechtrager/xar.git $XAR_REF
apple-libtapi https://github.com/tpoechtrager/apple-libtapi.git $APPLE_LIBTAPI_REF patched-stdint
cctools-port https://github.com/tpoechtrager/cctools-port.git $CCTOOLS_PORT_REF
MacOSX10.15.sdk.tar.xz sha256:$actual_sdk_sha256
EOF

temporary_output="$output.part"
rm -f "$temporary_output"
LC_ALL=C tar \
  --sort=name \
  --format=posix \
  --pax-option=delete=atime,delete=ctime \
  --mtime="@$source_date_epoch" \
  --owner=0 --group=0 --numeric-owner \
  -C "$work_dir" -cf - cross | gzip -n -9 >"$temporary_output"
mv "$temporary_output" "$output"

printf 'Created %s\n' "$output"
sha256sum "$output"

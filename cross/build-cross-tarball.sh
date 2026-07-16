#!/usr/bin/env bash

set -euo pipefail

# DEFAULT_SDK_SHA256 is from sha256sum of MacOSX10.15.sdk.tar.xz extracted
# from the published legacy cross.tar.gz. DEFAULT_SOURCE_DATE_EPOCH is a fixed
# 2020-08-27 16:00:00 UTC normalization time based on that archive's build date;
# it is intentionally stable, not an exact timestamp recovered from its metadata.
readonly DEFAULT_SDK_SHA256="05c98ed96b677dfba862356cba317cdcb7bfdff973150a60e0d1027da705c4cc"
readonly DEFAULT_SOURCE_DATE_EPOCH="1598544000"
readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# These revisions reproduce the source versions in the legacy 2020 bundle.
# Override any REF variable in the environment to intentionally update a source.
OSXCROSS_REF="${OSXCROSS_REF:-cc1823a726bb4ca8cd76f8702180d9f1de4a4748}"
XAR_REF="${XAR_REF:-2b9a4ab7003f1db8c54da4fea55fcbb424fdecb0}"
APPLE_LIBTAPI_REF="${APPLE_LIBTAPI_REF:-86f43cdb62a3ceb39f3ee6e4568eded67a4912e8}"
COMPILER_RT_REF="${COMPILER_RT_REF:-c1a0a213378a458fbea1a5c77b315c7dce08fd05}"
CCTOOLS_PORT_REF="${CCTOOLS_PORT_REF:-6c438753d2252274678d3e0839270045698c159b}"
LLVM_DSYMUTIL_REF="${LLVM_DSYMUTIL_REF:-6fe249efadf6139a7f271fee87a5a0f44e2454cf}"
DARLING_DMG_REF="${DARLING_DMG_REF:-71cc76c792db30328663272788c0b64aca27fdb0}"
P7ZIP_REF="${P7ZIP_REF:-2f60a51ac3aa2507d36df3c4f58f71a3716b1357}"
PBZX_REF="${PBZX_REF:-2a4d7c3300c826d918def713a24d25c237c8ed53}"

sdk=""
sdk_sha256="${SDK_SHA256:-$DEFAULT_SDK_SHA256}"
output="cross.tar.gz"
source_date_epoch="${SOURCE_DATE_EPOCH:-$DEFAULT_SOURCE_DATE_EPOCH}"

usage() {
  cat <<'EOF'
Usage: build-cross-tarball.sh --sdk PATH [options]

Create the cross.tar.gz source bundle consumed by openshift-golang-builder.

Options:
  --sdk PATH          MacOSX10.15.sdk.tar.xz input (required)
  --sdk-sha256 HASH   Expected SDK SHA-256 (default: legacy bundle checksum)
  --output PATH       Output archive (default: ./cross.tar.gz)
  -h, --help          Show this help

Source revisions can be changed with OSXCROSS_REF, APPLE_LIBTAPI_REF,
CCTOOLS_PORT_REF, COMPILER_RT_REF, XAR_REF, LLVM_DSYMUTIL_REF,
DARLING_DMG_REF, P7ZIP_REF, and PBZX_REF. SOURCE_DATE_EPOCH controls the
normalized archive timestamp.
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

for command in awk dirname git gzip install mktemp patch sha256sum tar; do
  command -v "$command" >/dev/null || die "required command not found: $command"
done

actual_sdk_sha256=$(sha256sum "$sdk" | awk '{print $1}')
[[ "$actual_sdk_sha256" == "${sdk_sha256,,}" ]] ||
  die "SDK SHA-256 is $actual_sdk_sha256, expected ${sdk_sha256,,}"

mkdir -p "$(dirname "$output")"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/cross-tarball.XXXXXXXX")
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/cross/deps" "$work_dir/cross/osxcross"

clone_git_source() {
  local repository=$1
  local ref=$2
  local branch=$3
  local destination=$4
  local history=${5:-shallow}
  local url="https://github.com/$repository.git"
  local depth_args=(--depth=1)

  printf 'Cloning %s at %s\n' "$repository" "$ref"
  if [[ "$history" == full ]]; then
    depth_args=()
  fi

  git init --quiet "$destination"
  git -C "$destination" remote add origin "$url"
  git -C "$destination" fetch --quiet "${depth_args[@]}" origin \
    "$ref:refs/remotes/origin/$branch"
  git -C "$destination" checkout --quiet -b "$branch" --track "origin/$branch"
}

clone_git_source tpoechtrager/osxcross "$OSXCROSS_REF" master "$work_dir/cross/osxcross"
clone_git_source tpoechtrager/xar "$XAR_REF" master "$work_dir/cross/deps/xar"
clone_git_source tpoechtrager/apple-libtapi "$APPLE_LIBTAPI_REF" 1100.0.11 "$work_dir/cross/deps/apple-libtapi"
clone_git_source llvm/llvm-project "$COMPILER_RT_REF" release/9.x "$work_dir/cross/deps/compiler-rt"
clone_git_source tpoechtrager/cctools-port "$CCTOOLS_PORT_REF" 949.0.1-ld64-530 "$work_dir/cross/deps/cctools-port"
clone_git_source tpoechtrager/llvm-dsymutil "$LLVM_DSYMUTIL_REF" master "$work_dir/cross/deps/llvm-dsymutil"
clone_git_source LubosD/darling-dmg "$DARLING_DMG_REF" master "$work_dir/cross/deps/darling-dmg" full
clone_git_source tpoechtrager/p7zip "$P7ZIP_REF" master "$work_dir/cross/deps/p7zip"
clone_git_source tpoechtrager/pbzx "$PBZX_REF" master "$work_dir/cross/deps/pbzx"

# This is the tracked local change present in the legacy cross.tar.gz.
patch -d "$work_dir/cross/deps/cctools-port" -p1 \
  <"$SCRIPT_DIR/cctools-blobcore-clone.patch"

mkdir -p "$work_dir/cross/osxcross/build" "$work_dir/cross/osxcross/tarballs"
install -m 0644 "$sdk" "$work_dir/cross/osxcross/tarballs/MacOSX10.15.sdk.tar.xz"

cat >"$work_dir/cross/SOURCES" <<EOF
osxcross https://github.com/tpoechtrager/osxcross.git $OSXCROSS_REF
xar https://github.com/tpoechtrager/xar.git $XAR_REF
apple-libtapi https://github.com/tpoechtrager/apple-libtapi.git $APPLE_LIBTAPI_REF
compiler-rt https://github.com/llvm/llvm-project.git $COMPILER_RT_REF
cctools-port https://github.com/tpoechtrager/cctools-port.git $CCTOOLS_PORT_REF patched-blob-clone
llvm-dsymutil https://github.com/tpoechtrager/llvm-dsymutil.git $LLVM_DSYMUTIL_REF
darling-dmg https://github.com/LubosD/darling-dmg.git $DARLING_DMG_REF
p7zip https://github.com/tpoechtrager/p7zip.git $P7ZIP_REF
pbzx https://github.com/tpoechtrager/pbzx.git $PBZX_REF
MacOSX10.15.sdk.tar.xz sha256:$actual_sdk_sha256
EOF

for dependency in apple-libtapi cctools-port compiler-rt darling-dmg llvm-dsymutil p7zip pbzx xar; do
  variable_name=${dependency//-/_}_ref
  variable_name=${variable_name^^}
  printf '%s\n' "${!variable_name}" >"$work_dir/cross/osxcross/build/.${dependency}_git_hash"
done

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

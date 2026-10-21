#!/bin/bash
# ART-22737: build /releases/*.tar.gz for one OCP release so that every inner binary equals what promote
# publishes on mirror.openshift.com today (`oc adm release extract --tools` for openshift-install and
# publish_baremetal_installer_binary for the FIPS installer).
# Inputs: /in/<goarch>/{installer,artifacts,baremetal}/ copied from the release's images by the Dockerfile.
# Names: openshift-install-<flavor>-<os>-<arch>.tar.gz and ${FIPS_BIN}-<flavor>-linux-<arch>.tar.gz, where
# <flavor> is the mirror directory: x86_64, aarch64, ppc64le, s390x or multi-<goarch>.
# Like oc, optional binaries (linux_amd64, linux_arm64, mac_arm64 in installer-artifacts) are packed only when
# the image has them; EXPECTED_TARBALLS (from the mirror listing) fails the build on any difference.
# REQUIRED_MARKERS lists the markers every binary must have (the architecture marker only exists from 4.17).
set -euo pipefail

: "${RELEASE_VERSION:?}" "${RELEASE_REPO:?}" "${FIPS_BIN:?}" "${EXPECTED_TARBALLS:?}" "${REQUIRED_MARKERS:?}"
declare -A BREW=([amd64]=x86_64 [arm64]=aarch64 [ppc64le]=ppc64le [s390x]=s390x)

digest_of() {
  local var="DIGEST_${BREW[$1]^^}"
  [[ "${!var:-}" =~ ^sha256:[0-9a-f]{64}$ ]] || { echo "build arg $var is not a sha256 digest: '${!var:-}'" >&2; exit 1; }
  echo "${!var}"
}

pack() {
  IFS='|' read -r out src bin image arch resign readme <<<"$1"
  local d
  d=$(mktemp -d /work/pack.XXXXXX)
  cp "$src" "$d/$bin"
  python3 /work/inject.py "$d/$bin" --image "$image" --version "$RELEASE_VERSION" --arch "$arch" \
    --require "$REQUIRED_MARKERS" ${resign:+--resign-macho}
  local files=("$bin")
  if [ -n "$readme" ]; then cp /work/README.md "$d/"; files=(README.md "$bin"); fi
  chmod 0755 "$d/$bin"
  (cd "$d" && sha256sum "$bin" | sed "s|  $bin\$|  $out:$bin|") >>/work/inner-sha256.txt
  tar -C "$d" -czf "/releases/$out" "${files[@]}"
  rm -rf "$d"
}
export -f pack
export RELEASE_VERSION REQUIRED_MARKERS

jobs() {
  local flavor=$1 g=$2 image=$3 arch=$4 i=/in/$2 a
  echo "openshift-install-$flavor-linux-$g.tar.gz|$i/installer/openshift-install|openshift-install|$image|$arch||y"
  for a in amd64 arm64; do
    if [ "$a" != "$g" ] && [ -f "$i/artifacts/linux_$a/openshift-install" ]; then
      echo "openshift-install-$flavor-linux-$a.tar.gz|$i/artifacts/linux_$a/openshift-install|openshift-install|$image|$arch||y"
    fi
  done
  echo "openshift-install-$flavor-mac-amd64.tar.gz|$i/artifacts/mac/openshift-install|openshift-install|$image|$arch||y"
  if [ -f "$i/artifacts/mac_arm64/openshift-install" ]; then
    echo "openshift-install-$flavor-mac-arm64.tar.gz|$i/artifacts/mac_arm64/openshift-install|openshift-install|$image|$arch|y|y"
  fi
  echo "$FIPS_BIN-$flavor-linux-$g.tar.gz|$i/baremetal/openshift-install|$FIPS_BIN|$image|$arch||"
}

GOARCHES=()
for g in amd64 arm64 ppc64le s390x; do
  [ -d "/in/$g" ] && GOARCHES+=("$g")
done
[ "${#GOARCHES[@]}" -gt 0 ] || { echo "no /in/<goarch> inputs" >&2; exit 1; }

mkdir -p /releases /work
: >/work/inner-sha256.txt
{
  for g in "${GOARCHES[@]}"; do
    digest=$(digest_of "$g")
    jobs "${BREW[$g]}" "$g" "$RELEASE_REPO@$digest" "linux/$g"
  done
  if [ -n "${DIGEST_MULTI:-}" ]; then
    [[ "$DIGEST_MULTI" =~ ^sha256:[0-9a-f]{64}$ ]] || { echo "build arg DIGEST_MULTI is not a sha256 digest" >&2; exit 1; }
    [ "${#GOARCHES[@]}" -eq 4 ] || { echo "DIGEST_MULTI needs inputs for all four arches" >&2; exit 1; }
    for g in "${GOARCHES[@]}"; do
      jobs "multi-$g" "$g" "$RELEASE_REPO@$DIGEST_MULTI" "multi (linux/$g)"
    done
  fi
} >/work/jobs.txt
xargs -d '\n' -P "${PACK_JOBS:-$(nproc)}" -I{} bash -c 'pack "$1"' _ {} </work/jobs.txt
sort -k2 -o /work/inner-sha256.txt /work/inner-sha256.txt
cat /work/inner-sha256.txt
ls -l /releases
count=$(find /releases -maxdepth 1 -name '*.tar.gz' | wc -l)
[ "$count" -eq "$EXPECTED_TARBALLS" ] || { echo "built $count tarballs, expected $EXPECTED_TARBALLS" >&2; exit 1; }

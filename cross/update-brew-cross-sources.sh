#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_ARTIFACT_BASE_URL="https://ocp-artifacts.engineering.redhat.com/pub/RHOCP/build-deps/openshift-golang-builder"
readonly DEFAULT_DISTGIT_REPO="containers/openshift-golang-builder"
readonly DEFAULT_DISTGIT_BRANCH="rhaos-4.22-rhel-9"
readonly DEFAULT_DISTGIT_GIT_URL="https://pkgs.devel.redhat.com/git/containers/openshift-golang-builder"

artifact_base_url="${CROSS_ARTIFACT_BASE_URL:-$DEFAULT_ARTIFACT_BASE_URL}"
distgit_repo="${BREW_DISTGIT_REPO:-$DEFAULT_DISTGIT_REPO}"
distgit_branch="${BREW_DISTGIT_BRANCH:-$DEFAULT_DISTGIT_BRANCH}"
distgit_git_url="${BREW_DISTGIT_GIT_URL:-$DEFAULT_DISTGIT_GIT_URL}"
dry_run=false

usage() {
  cat <<'EOF'
Usage: update-brew-cross-sources.sh [--dry-run] [--branch DISTGIT_BRANCH]

Download and verify the published cross.tar.gz, then upload it to the Brew
lookaside cache. The distgit clone is temporary; this script never commits or
pushes to a distgit branch.

Environment overrides:
  CROSS_ARTIFACT_BASE_URL  Directory containing cross.tar.gz and sha256sum.txt
  BREW_DISTGIT_REPO        Distgit repository (default: containers/openshift-golang-builder)
  BREW_DISTGIT_BRANCH      Branch used only to establish an rhpkg context
  BREW_DISTGIT_GIT_URL     Read-only distgit URL used by --dry-run

Options:
  --branch BRANCH  Branch used only to establish an rhpkg context
  --dry-run        Generate the sources entry offline without uploading
  -h, --help       Show this help

Copy the generated sources entry into the source-context sources file in each
relevant ocp-build-data branch.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    --branch)
      (($# >= 2)) || die "--branch requires a value"
      distgit_branch=$2
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
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

for command in awk basename curl git mktemp rhpkg sha256sum; do
  command -v "$command" >/dev/null || die "required command not found: $command"
done
git check-ref-format --branch "$distgit_branch" >/dev/null ||
  die "invalid branch name: $distgit_branch"

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/brew-cross-lookaside.XXXXXXXX")
trap 'rm -rf "$work_dir"' EXIT

artifact_dir="$work_dir/artifact"
mkdir -p "$artifact_dir"
artifact_base_url=${artifact_base_url%/}

printf 'Downloading cross.tar.gz and sha256sum.txt\n'
curl --fail --silent --show-error --location --retry 3 \
  --output "$artifact_dir/cross.tar.gz" \
  "$artifact_base_url/cross.tar.gz"
curl --fail --silent --show-error --location --retry 3 \
  --output "$artifact_dir/sha256sum.txt" \
  "$artifact_base_url/sha256sum.txt"

(
  cd "$artifact_dir"
  sha256sum --check --strict sha256sum.txt
)

archive_sha256=$(sha256sum "$artifact_dir/cross.tar.gz" | awk '{print $1}')
printf 'Verified SHA-256: %s\n' "$archive_sha256"

if [[ $dry_run == true ]]; then
  git clone --branch "$distgit_branch" "$distgit_git_url" \
    "$work_dir/$(basename "$distgit_repo")"
else
  (
    cd "$work_dir"
    rhpkg clone -b "$distgit_branch" "$distgit_repo"
  )
fi

distgit_dir="$work_dir/$(basename "$distgit_repo")"
[[ -d "$distgit_dir/.git" ]] || die "distgit clone did not create $distgit_dir"

cp "$artifact_dir/cross.tar.gz" "$distgit_dir/cross.tar.gz"
(
  cd "$distgit_dir"
  if [[ $dry_run == true ]]; then
    rhpkg new-sources --offline cross.tar.gz
  else
    rhpkg new-sources cross.tar.gz
  fi
)

[[ -s "$distgit_dir/sources" ]] || die "rhpkg did not generate a sources file"
printf 'Generated sources entry:\n'
cat "$distgit_dir/sources"

if [[ $dry_run == true ]]; then
  printf 'Dry run complete; no lookaside upload was performed.\n'
else
  printf 'Lookaside upload complete; no distgit commit or push was performed.\n'
fi

#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_ARTIFACT_BASE_URL="https://ocp-artifacts.engineering.redhat.com/pub/RHOCP/build-deps/openshift-golang-builder"
readonly DEFAULT_DISTGIT_REPO="containers/openshift-golang-builder"
readonly DEFAULT_DISTGIT_GIT_URL="https://pkgs.devel.redhat.com/git/containers/openshift-golang-builder"
readonly DEFAULT_COMMIT_MESSAGE="Update cross.tar.gz"

artifact_base_url="${CROSS_ARTIFACT_BASE_URL:-$DEFAULT_ARTIFACT_BASE_URL}"
distgit_repo="${BREW_DISTGIT_REPO:-$DEFAULT_DISTGIT_REPO}"
distgit_git_url="${BREW_DISTGIT_GIT_URL:-$DEFAULT_DISTGIT_GIT_URL}"
commit_message="${CROSS_DISTGIT_COMMIT_MESSAGE:-$DEFAULT_COMMIT_MESSAGE}"
dry_run=false
branches=()
branches_to_update=()
updated_count=0
declare -A seen_branches=()

usage() {
  cat <<'EOF'
Usage: update-brew-cross-sources.sh [--dry-run] BRANCH [BRANCH ...]

Download and verify the published cross.tar.gz, upload it to the Brew
lookaside cache, and update each specified openshift-golang-builder distgit
branch to use it.

Environment overrides:
  CROSS_ARTIFACT_BASE_URL       Directory containing cross.tar.gz and sha256sum.txt
  BREW_DISTGIT_REPO             Distgit repository (default: containers/openshift-golang-builder)
  BREW_DISTGIT_GIT_URL          Read-only distgit URL used by --dry-run
  CROSS_DISTGIT_COMMIT_MESSAGE  Commit message (default: Update cross.tar.gz)

Options:
  --dry-run  Verify and compare the archive without uploading, committing, or pushing
  -h, --help  Show this help

The script commits and pushes directly to every specified distgit branch.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while (($#)); do
  case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      if [[ ! ${seen_branches[$1]+set} ]]; then
        branches+=("$1")
        seen_branches[$1]=1
      fi
      shift
      ;;
  esac
done

((${#branches[@]} > 0)) || die "at least one distgit branch is required"

for command in awk basename cmp curl git md5sum mktemp sha256sum sha512sum; do
  command -v "$command" >/dev/null || die "required command not found: $command"
done
if [[ $dry_run == false ]]; then
  command -v rhpkg >/dev/null || die "required command not found: rhpkg"
fi

for branch in "${branches[@]}"; do
  git check-ref-format --branch "$branch" >/dev/null ||
    die "invalid branch name: $branch"
done

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/brew-cross-sources.XXXXXXXX")
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
archive_md5=$(md5sum "$artifact_dir/cross.tar.gz" | awk '{print $1}')
archive_sha512=$(sha512sum "$artifact_dir/cross.tar.gz" | awk '{print $1}')
printf 'Verified SHA-256: %s\n' "$archive_sha256"
printf 'Archive MD5: %s\n' "$archive_md5"

first_branch=${branches[0]}
if [[ $dry_run == true ]]; then
  git clone --branch "$first_branch" "$distgit_git_url" \
    "$work_dir/$(basename "$distgit_repo")"
else
  (
    cd "$work_dir"
    rhpkg clone -b "$first_branch" "$distgit_repo"
  )
fi

distgit_dir="$work_dir/$(basename "$distgit_repo")"
[[ -d "$distgit_dir/.git" ]] || die "distgit clone did not create $distgit_dir"

git -C "$distgit_dir" fetch origin
for branch in "${branches[@]}"; do
  git -C "$distgit_dir" show-ref --verify --quiet "refs/remotes/origin/$branch" ||
    die "distgit branch not found: $branch"
done

sources_matches_archive() {
  local sources_file=$1

  awk \
    -v md5="$archive_md5" \
    -v sha256="$archive_sha256" \
    -v sha512="$archive_sha512" '
      ($1 == md5 || $1 == sha256 || $1 == sha512) &&
          ($2 == "cross.tar.gz" || $2 == "*cross.tar.gz") { found = 1 }
      $1 == "SHA256" && $2 == "(cross.tar.gz)" && $3 == "=" && $4 == sha256 { found = 1 }
      $1 == "SHA512" && $2 == "(cross.tar.gz)" && $3 == "=" && $4 == sha512 { found = 1 }
      END { exit !found }
    ' "$sources_file"
}

branch_index=0
for branch in "${branches[@]}"; do
  branch_sources="$work_dir/branch-sources-$branch_index"
  ((branch_index += 1))

  if git -C "$distgit_dir" show "origin/$branch:sources" >"$branch_sources" 2>/dev/null &&
    sources_matches_archive "$branch_sources"; then
    printf '%s already references the published archive; skipping\n' "$branch"
  else
    branches_to_update+=("$branch")
  fi
done

if ((${#branches_to_update[@]} == 0)); then
  printf 'All %s distgit branch(es) already reference the published archive.\n' \
    "${#branches[@]}"
  exit 0
fi

if [[ $dry_run == true ]]; then
  printf 'Dry run: would upload cross.tar.gz with MD5 %s to Brew lookaside.\n' \
    "$archive_md5"
  for branch in "${branches_to_update[@]}"; do
    printf 'Dry run: would update %s.\n' "$branch"
  done
  printf 'Dry run: no lookaside upload, commit, or push was performed.\n'
  exit 0
fi

cp "$artifact_dir/cross.tar.gz" "$distgit_dir/cross.tar.gz"
(
  cd "$distgit_dir"
  rhpkg new-sources cross.tar.gz
)

generated_sources="$work_dir/sources"
[[ -s "$distgit_dir/sources" ]] || die "rhpkg did not generate a sources file"
cp "$distgit_dir/sources" "$generated_sources"
printf 'Generated sources entry:\n'
cat "$generated_sources"

if git -C "$distgit_dir" ls-files --error-unmatch sources >/dev/null 2>&1; then
  git -C "$distgit_dir" restore --staged --worktree -- sources
else
  rm -f "$distgit_dir/sources"
fi
rm -f "$distgit_dir/cross.tar.gz"

for branch in "${branches_to_update[@]}"; do
  printf '\nUpdating %s\n' "$branch"
  git -C "$distgit_dir" checkout --detach "origin/$branch"

  if [[ -f "$distgit_dir/sources" ]] &&
    cmp --silent "$generated_sources" "$distgit_dir/sources"; then
    printf '%s already references this archive; skipping\n' "$branch"
    continue
  fi

  cp "$generated_sources" "$distgit_dir/sources"
  git -C "$distgit_dir" add -- sources
  git -C "$distgit_dir" commit -m "$commit_message" -- sources
  git -C "$distgit_dir" push origin "HEAD:refs/heads/$branch"
  ((updated_count += 1))
done

printf '\nUpdated %s distgit branch(es); %s already current.\n' \
  "$updated_count" "$(( ${#branches[@]} - updated_count ))"

#!/bin/sh
set -euxo pipefail

# DNF_WRAPPER_DIR and other env vars are set in the Dockerfile for the image.
# Ensure they are set.

if [[ -z "${DNF_WRAPPER_DIR}" || -z "${ART_REPOS_DIR_CI}" || -z "${ART_REPOS_DIR_LOCALDEV}" ]]; then
  echo "One or more environment variables are not set by Dockerfile ENV. Exiting since environment is not expected."
  exit 1
fi

mkdir -p "${DNF_WRAPPER_DIR}"

# Create directories where .repo files can be stored for dnf_wrapper.sh's use.
mkdir -p "${ART_REPOS_DIR_CI}"
mkdir -p "${ART_REPOS_DIR_LOCALDEV}"

wrap_command() {
  local command_name="$1"
  if which ${command_name}; then
    # The command in available in $PATH
    local real_command_path=$(which ${command_name})
    ln -s "${real_command_path}" "${DNF_WRAPPER_DIR}/${command_name}.real"
    # /tmp/dnf_wrapper.sh is copied into place by the Dockerfile
    cp /tmp/dnf_wrapper.sh "${DNF_WRAPPER_DIR}/${command_name}"
    chmod +x "${DNF_WRAPPER_DIR}/${command_name}"
    echo "Installed wrapper for ${command_name}"
  fi
}

# Allow repos to be skipped if they are not responsive. Reasons:
# 1. A single misconfigured repo in the CI mirroring service should not break all CI.
# 2. If a user it not connected to the VPN, the internal repos will not be accessible, but should not break all yum operations.
# Only configure if we're not on a microdnf-based system (ubi9-minimal)
# Note: openshift-enterprise-base-rhel9 creates symlinks /usr/bin/yum -> microdnf-wrapper.sh on minimal systems
if [ -x /usr/bin/microdnf ]; then
  echo "Detected microdnf system, skipping config-manager (not supported)"
elif which yum >/dev/null 2>&1; then
  yum config-manager --setopt=skip_if_unavailable=True --save
  echo "Configured yum repos with config-manager"
elif which dnf >/dev/null 2>&1; then
  dnf config-manager --setopt=skip_if_unavailable=True --save
  echo "Configured dnf repos with config-manager"
else
  echo "No package manager found for repo configuration"
fi

# Wrap package managers that exist in the base image
wrap_command yum
wrap_command dnf
wrap_command microdnf



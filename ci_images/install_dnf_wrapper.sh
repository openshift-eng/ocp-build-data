#!/bin/sh
set -euxo pipefail

# DNF_WRAPPER_DIR is set in the Dockerfile for the image.
mkdir -p "${DNF_WRAPPER_DIR}"

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
yum config-manager --setopt=skip_if_unavailable=True --save

# SSL certificates for ocp-artifacts will not be trusted by default
# CAs, so ignore ssl requirements. http is used by the in-cluster
# build farms.
yum config-manager --setopt=skip_if_unavailable=True --save

wrap_command yum
wrap_command dnf



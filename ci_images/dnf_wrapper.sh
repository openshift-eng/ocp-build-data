#!/bin/sh

##########################################
# The purpose of this script is to wrap yum/dnf invocations that are issued by CI workloads.
# CI workloads needs access to RHEL and ART RPMs when they run, but they do not have direct
# access to the Red Hat CDN or plashets. Instead, their requests must be proxied through
# a content-mirroring service run on build-farms. The content mirror serves RPMs sourced
# from backends like mriror.openshift.com/enterprise and the Red Hat CDN.
# The backends are configured in configuration files like:
#    https://github.com/openshift/release/blob/ca8e034ced5fd4931175774f5eb0ba5b53d1c379/core-services/release-controller/_repos/ocp-4.11-rhel8.repo
# curling the content mirroring service outputs a yum repo file with repositories
# that will cause yum to reach back through the content mirroring service for RPMs.
# See https://docs.google.com/document/d/1GqmPMzeZ0CmVZhdKF_Q_TdRqx_63TIRboO4uvqejPAY/edit#heading=h.qyfinv34w83c for more information.
##########################################

set -euo pipefail

LOG_PREFIX="ART yum/dnf wrapper [$$]:"

echoerr() {
  echo -n "${LOG_PREFIX} " 1>&2
  cat <<< "$@" 1>&2
}

if [[ -z "${DNF_WRAPPER_DIR:-}" ]]; then
  echo "Expected DNF_WRAPPER_DIR to be set. Exiting since environment is not expected."
  exit 1
fi

# CI_RPM_SVC should be injected into the rebased Dockerfile from the doozer image
# metadata config (the .envs list).
if [[ -z "${CI_RPM_SVC:-}" ]]; then
  echo "Expected CI_RPM_SVC to be set. Exiting since environment is not expected."
  exit 1
fi

SKIP_REPO_INSTALL="0"

if [[ -f "/tmp/tls-ca-bundle.pem" ]]; then
  # This PEM is copied into place for a brew build. We never want to affect
  # repos when running a brew build.
  SKIP_REPO_INSTALL="1"
  echoerr "Detected a brew build - no repos will be changed."
fi

if [[ "${OPENSHIFT_CI:-}" != "true" ]]; then
  # All of our Dockerfiles set this. This check is here to ensure that no one just runs this
  # on their workstation and deletes their yum configuration files.
  SKIP_REPO_INSTALL="1"
  echoerr "OPENSHIFT_CI != true, so not executing in the expected environment - no repos will be changed."
fi

# Container hostnames will change every run, so this helps ensure we try
# to acquire repo context when ever we start a new instance of the image.
FIRST_RUN_MARKER="/tmp/first-dnf-wrapper-run-$(hostname)"

if [[ ! -f "${FIRST_RUN_MARKER}" && "${SKIP_REPO_INSTALL}" == "0" ]]; then
  rm -rf /etc/yum.repos.d/*

  INSTALL_ART_REPOS="0"
  if [[ -f "/var/run/secrets/kubernetes.io" ]]; then
    # We are running inside of a pod. Assume that this is a build farm
    # and we can find the RPM mirroring services.
    if curl --fail "${CI_RPM_SVC}" > /etc/yum.repos.d/ci-rpm-mirrors.repo; then
      echoerr "Installed CI repo definitions from ${CI_RPM_SVC}..."
    else
      echoerr "WARNING: Running inside kubernetes pod, but unable to query OpenShift Test Platform RPM mirror information from: ${CI_RPM_SVC}"
      rm -f "/etc/yum.repos.d/ci-rpm-mirrors.repo"
      INSTALL_ART_REPOS="1"
    fi
  else
    echoerr "Did not detect that this script is running in a kubernetes pod. Will not install CI repositories."
    INSTALL_ART_REPOS="1"
  fi

  if [[ "${INSTALL_ART_REPOS}" == "1" ]]; then
    cp "${DNF_WRAPPER_DIR}/unsigned.repo" /etc/yum.repos.d/art-unsigned.repo
    echoerr "Installed repos that can be used when connected to the VPN."
  fi

  touch "${FIRST_RUN_MARKER}"
fi

$0.real "$@"
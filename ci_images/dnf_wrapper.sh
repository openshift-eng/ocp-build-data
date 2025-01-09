#!/bin/bash

# *********************************************************
# WARNING: issues in this script can break CI for an entire Z stream. When making changes, see "dnf_wrapper_test.Dockerfile" for information on how to test those changes.
# *********************************************************

##########################################
# The purpose of this script is to wrap yum/dnf invocations that are issued by CI workloads or local docker builds of OCP components.
# Both invocations need access to RHEL and ART RPMs during the build process if they are installing RPMS, but they do not have direct
# access to the Red Hat CDN or plashets.
# RPMS are made available in different ways depending on the way the container is being run.
# 1. If the container is running as a build in OCP Test Platform, RPMs are obtained through the RPM mirroring service available in CI.
# 2. If the container is being run on an engineer's system with "podman build ...", then RPMs can be obtained from hosts accessible via the Red Hat VPN.
# 3. If the script is run with the ART_DNF_WRAPPER_POLICY environment variable set to "skip", then the base image repositories will be used (host must have subscription to access RHEL content).
# This script detects which mode is being used at runtime and uses dnf's "repodir" search path option to change which repo files
# dnf will search.
# When running as a pod in a CI build, the content RPM mirror serves RPMs sourced
# from backends like mirror.openshift.com/enterprise and the Red Hat CDN.
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

# External users of this image may have different use cases that diverge
# from our default repo installation logic. Allow them to override
# the behavior.
# "default" - Install RPM service repos if running in pod. Install VPN repos if not.
# "append" - Do not remove base image .repo files from dnf runs - only add ART repos based on invocation context.
# "skip" - Leave base image repositories intact.
ART_DNF_WRAPPER_POLICY="${ART_DNF_WRAPPER_POLICY:-default}"

if [[ "${ART_DNF_WRAPPER_POLICY}" == "skip" ]]; then
  SKIP_REPO_INSTALL="1"
else
  SKIP_REPO_INSTALL="0"
  INCLUDE_BASE_IMAGE_REPOS="0"

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

  if [[ "${ART_DNF_WRAPPER_POLICY}" == "append" ]]; then
    INCLUDE_BASE_IMAGE_REPOS="1"
  fi

fi

# Container hostnames will differ every run, so this helps ensure we try
# to acquire repo context whenever we start a new instance of the image
# even if /tmp is shared between containers.
WRAPPER_MODE_MARKER="/tmp/first-dnf-wrapper-run-$HOSTNAME"

# If we install repos appropriate for CI builds, they will reside here.
CI_RPM_REPO_DEST="${ART_REPOS_DIR_CI}/ci-svc-repos.repo"
VPN_RPM_REPO_DEST="${ART_REPOS_DIR_LOCALDEV}/rh-vpn-repos.repo"

EXTRA_DNF_ARGS=""

if [[ "${SKIP_REPO_INSTALL}" == "0" ]]; then
  WRAPPER_MODE="unknown"

  if [[ ! -f "${WRAPPER_MODE_MARKER}" ]]; then
    # When not running in CI (e.g. if an engineer is running a local docker build on a Dockerfile)
    # we can try to use repos available within the Red Hat firewall. They are not meant for
    # use in a CI pod, but allow engineers to access RHEL content/plashet content if they are connected
    # to the VPN. INSTALL_ART_RH_VPN_REPOS will remain at "1" if we should install these VPN repos.
    # If we instead find that the CI_RPM_SVC is available (this should be true only if
    # we are running as a pod in OCP Test Platform CI, the VPN repos will not be installed.
    INSTALL_ART_RH_VPN_REPOS="1"
    echoerr "Checking for CI build pod repo definitions..."
    for (( i=1; i<=5; i++ )); do
      if curl --fail "${CI_RPM_SVC}" 2> /dev/null > "${CI_RPM_REPO_DEST}"; then
        WRAPPER_MODE="ci"
        INSTALL_ART_RH_VPN_REPOS="0"
        echoerr "Installed CI build pod repo definitions from ${CI_RPM_SVC}."
        break
      fi
      rm -f "${CI_RPM_REPO_DEST}"
      sleep 1
    done

    if [[ "${INSTALL_ART_RH_VPN_REPOS}" == "1" ]]; then
      echoerr "Did not detect that this script is running in a CI build pod. Will not install CI repositories."
      curl --fail --silent --location --retry 5 --retry-delay 2 --output /etc/pki/ca-trust/source/anchors/IT-Root-CAs.pem https://certs.corp.redhat.com/certs/Current-IT-Root-CAs.pem
      update-ca-trust extract
      cp "${DNF_WRAPPER_DIR}/unsigned.repo" "${VPN_RPM_REPO_DEST}"
      WRAPPER_MODE="localdev"
      echoerr "Installed repos that can be used when connected to the VPN."
    fi

    # Store the mode in the marker file
    echo "${WRAPPER_MODE}" > "${WRAPPER_MODE_MARKER}"
  else
    # Otherwise, the marker exists. Read the current mode.
    WRAPPER_MODE=$(cat "${WRAPPER_MODE_MARKER}")
  fi

  DNF_OPTS_REPOSDIR=""
  if [[ "${WRAPPER_MODE}" == "ci" ]]; then
    # If in CI mode, include the ci reposdir in the dnf search path
    DNF_OPTS_REPOSDIR="${ART_REPOS_DIR_CI}"
  elif [[ "${WRAPPER_MODE}" == "localdev" ]]; then
    # If in localdev mode, include the localdev reposdir in the dnf search path
    DNF_OPTS_REPOSDIR="${ART_REPOS_DIR_LOCALDEV}"
  fi

  if [[ "${DNF_OPTS_REPOSDIR}" != "" ]]; then
    if [[ "${INCLUDE_BASE_IMAGE_REPOS}" == "1" ]]; then
      DNF_OPTS_REPOSDIR="${DNF_OPTS_REPOSDIR},/etc/yum.repos.d"
    else
      # If any ART repos files were populated and we are ignoring
      # base image repos, eliminate extraneous warnings by
      # disabling RH subscription manager plugin.
      EXTRA_DNF_ARGS="${EXTRA_DNF_ARGS} --disableplugin=subscription-manager"
    fi

    # Set the repo file search path for DNF
    EXTRA_DNF_ARGS="${EXTRA_DNF_ARGS} --setopt=reposdir=${DNF_OPTS_REPOSDIR}"
    echoerr "DNF will search for repo files in: ${DNF_OPTS_REPOSDIR}"
  fi

fi

$0.real ${EXTRA_DNF_ARGS} "$@"

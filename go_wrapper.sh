#!/bin/sh

LOG_PREFIX="Go compliance shim [$$] [${__doozer_group}][${__doozer_key}]:"

echoerr() {
  if [[ "${GO_COMPLIANCE_DEBUG}" == "1" || "${GO_COMPLIANCE_INFO}" == "1" ]]; then
    echo -n "${LOG_PREFIX} " 1>&2
    cat <<< "$@" 1>&2
  fi
}

stricterror() {
  echoerr "ERROR: terminating go build due to strict mode non-compliance"
  if [[ "${SHIM_TEST}" == "1" ]]; then
    echo "STRICTERROR"
  fi
}

# Neutralise the no_openssl build tag, which would otherwise disable the openssl
# crypto backend that FORCE_OPENSSL exists to mandate. Operates in place on the
# caller's "arg" variable rather than returning the new value, because the strict
# mode check has to be able to terminate the script -- which it could not do from
# the subshell of a command substitution.
scrub_no_openssl() {
  pre_arg="${arg}"
  arg=$(echo "${arg}" | sed 's/\bno_openssl\b/shim_prevented_no_openssl/g')
  if [[ "${pre_arg}" != "${arg}" ]]; then
    echoerr "non-compliant: eliminated no_openssl"
    if [[ "${STRICT_MODE_BASIC}" == "1" ]]; then
      stricterror
      exit 1
    fi
  fi
}

run_go() {
  if [[ "${SHIM_TEST}" == "1" ]]; then
    echoerr "running with SHIM_TEST=${SHIM_TEST}"
    echo -n "GOEXPERIMENT=${GOEXPERIMENT} CGO_ENABLED=${CGO_ENABLED} "
    if [[ -n "${GOFIPS140}" ]]; then
      echo -n "GOFIPS140=${GOFIPS140} "
    fi
    for arg in "${ARGS[@]}"; do
      echo -n "[${arg}]"
    done
  else
    # The Dockerfile must ensure that "go.real" is in the current $PATH
    echoerr "invoking real go binary"
    # Pass GO_COMPLIANCE_INFO=0 GO_COMPLIANCE_DEBUG=0 to the go invocation.
    # This is because go programs will sometimes invoke go programs. In one
    # scenario, the parent go program was trying to parse the stderr of the
    # child go invocation. Since the shim was outputting to stderr,
    # this parsing failed.
    GO_COMPLIANCE_INFO=0 GO_COMPLIANCE_DEBUG=0 go.real "${ARGS[@]}"
    EXT="$?"
    echoerr "Exited with: ${EXT}"
    exit "${EXT}"
  fi
}

# Create an array of command line arguments.
ARGS=("$@")

GO_COMPLIANCE_INFO=${GO_COMPLIANCE_INFO:-"1"}
GO_COMPLIANCE_FOD_MODE_INCLUDE=${GO_COMPLIANCE_FOD_MODE_INCLUDE:-'.*'}
GO_COMPLIANCE_CGO_ENABLED_INCLUDE=${GO_COMPLIANCE_CGO_ENABLED_INCLUDE:-'.*'}
GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE=${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE:-'.*'}
GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE=${GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE:-'.*'}
# GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE has no unconditional default here -- see
# the version check below, where it is only defaulted to '.*' when the
# built-in module is wanted by default. That way a value reaching the
# include/exclude check further down can only be there because either the
# version check defaulted it in, or a component configured it explicitly.
GO_COMPLIANCE_COVER=${GO_COMPLIANCE_COVER:-'0'}

if [[ -n "${OPENSHIFT_CI}" || "${__doozer_group}" == "openshift-"* ]]; then
  GO_COMPLIANCE_POLICY="${GO_COMPLIANCE_POLICY:-exempt_darwin,exempt_windows,exempt_cross_compile}"
  export GOTOOLCHAIN="local"
  echoerr "Forcing GOTOOLCHAIN=${GOTOOLCHAIN}"
else
  GO_COMPLIANCE_POLICY="exempt_all"
fi

if [[ "${GO_COMPLIANCE_DEBUG}" == "1" ]]; then
  echoerr "config GO_COMPLIANCE_POLICY=\"${GO_COMPLIANCE_POLICY}\" GO_COMPLIANCE_CGO_ENABLED_INCLUDE=\"${GO_COMPLIANCE_CGO_ENABLED_INCLUDE}\" GO_COMPLIANCE_CGO_ENABLED_EXCLUDE=\"${GO_COMPLIANCE_CGO_ENABLED_EXCLUDE}\" GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE=\"${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE}\" GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE=\"${GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE}\" GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE=\"${GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE}\" GO_COMPLIANCE_OPENSSL_ENABLED_EXCLUDE=\"${GO_COMPLIANCE_OPENSSL_ENABLED_EXCLUDE}\" GO_COMPLIANCE_FOD_MODE_INCLUDE=\"${GO_COMPLIANCE_FOD_MODE_INCLUDE}\" GO_COMPLIANCE_FOD_MODE_EXCLUDE=\"${GO_COMPLIANCE_FOD_MODE_EXCLUDE}\" GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE=\"${GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE}\" GO_COMPLIANCE_BUILTIN_FIPS_EXCLUDE=\"${GO_COMPLIANCE_BUILTIN_FIPS_EXCLUDE}\""

  echo 1>&2
  echo 1>&2
  echo -n "${LOG_PREFIX} incoming command line arguments: " 1>&2
  for arg in "$@"; do
    echo -n "\"${arg}\" " 1>&2
  done
  echo 1>&2
  echo 1>&2

  echoerr "incoming environment: "
  echoerr "---------------------"
  env 1>&2
  echoerr "---------------------"
  echo 1>&2
fi

echoerr "assessment: CGO_ENABLED=${CGO_ENABLED:-1}"
if cat <<< "$@" | grep "-extldflags.*-static" > /dev/null; then
  echoerr "assessment: static linking"
else
  echoerr "assessment: dynamic linking"
fi

# Basic strict mode requires incoming compiler
# invocation to be compliant EXCEPT for strictfipsmode.
STRICT_MODE_BASIC="0"
if [[ "${GO_COMPLIANCE_STRICT}" == "basic" ]]; then
  echoerr "setting strict_basic mode for FIPS compliance"
  STRICT_MODE_BASIC="1"
fi

# Full strict mode requires incoming compiler
# invocation to be compliant, including GOEXPERIMENT
# with strictfipsmode.
STRICT_MODE_FULL="0"
if [[ "${GO_COMPLIANCE_STRICT}" == "full" ]]; then
  echoerr "setting strict_full mode for FIPS compliance"
  STRICT_MODE_FULL="1"
  STRICT_MODE_BASIC="1"
fi

EXEMPT="0"
if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_darwin"* ]]; then
  if [[ "$GOOS" == "darwin" ]]; then
    echoerr "skipping forced compliance due to GOOS=${GOOS}"
    EXEMPT="1"
  fi
fi

if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_windows"* ]]; then
  if [[ "$GOOS" == "windows" ]]; then
    echoerr "skipping forced compliance due to GOOS=${GOOS}"
    EXEMPT="1"
  fi
fi

if [[ "${SHIM_TEST}" == "1" ]]; then
  FOUND_HOST_ARCH="amd64"
  FOUND_GO_VERSION="${SHIM_TEST_GO_VERSION:-go1.24.0}"
else
  FOUND_HOST_ARCH="$(go.real env GOHOSTARCH)"
  FOUND_GO_VERSION="$(go.real env GOVERSION)"
fi

# Go 1.26 ships a built-in, FIPS 140-3 validated cryptographic module, selected
# with GOFIPS140. It is pure Go, so none of the workarounds needed to steer
# earlier toolchains onto the openssl backend apply. OCP 5.0 and 5.1 both ship
# a golang 1.26 builder image, but the built-in module is only wanted from 5.1
# onwards, so on 1.26 specifically it takes corroboration from __doozer_group
# to qualify. golang 1.27+ always qualifies on its own.
#
# GO_BUILTIN_FIPS_AVAILABLE records whether this toolchain has a built-in
# module at all, regardless of whether it is wanted by default -- it is the
# capability, not the decision. GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE carries the
# decision: it is defaulted to '.*' below exactly when the module is wanted
# by default, and left alone otherwise. That means a component can still
# configure it explicitly to opt in or out (see the include/exclude check
# further down) without a separate flag to tell "explicitly configured" apart
# from "defaulted": if the version/group check below didn't default it, the
# only way it ends up non-empty is a component having set it itself.
GO_BUILTIN_FIPS_AVAILABLE="0"
GO_VER="${FOUND_GO_VERSION#go}"   # "go1.26.0" -> "1.26.0"
GO_MAJOR="${GO_VER%%.*}"          #            -> "1"
GO_REST="${GO_VER#*.}"            #            -> "26.0"
GO_MINOR="${GO_REST%%.*}"         #            -> "26"
# GOVERSION can carry a suffix (e.g. "go1.24.6 X:strictfipsruntime") which the
# parsing above tolerates, or be a devel string with no version at all. Only
# trust the result when both fields came out as numbers; anything else falls
# back to the openssl behaviour, which is the safe default.
if [[ "${GO_MAJOR}" =~ ^[0-9]+$ && "${GO_MINOR}" =~ ^[0-9]+$ ]]; then
  if [[ "${GO_MAJOR}" -gt 1 ]] || [[ "${GO_MAJOR}" -eq 1 && "${GO_MINOR}" -ge 26 ]]; then
    GO_BUILTIN_FIPS_AVAILABLE="1"
  fi
  if [[ "${GO_MAJOR}" -gt 1 ]] || [[ "${GO_MAJOR}" -eq 1 && "${GO_MINOR}" -ge 27 ]]; then
    GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE=${GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE:-'.*'}
  elif [[ "${GO_MAJOR}" -eq 1 && "${GO_MINOR}" -eq 26 ]]; then
    # __doozer_group is set by doozer to the OCP group being built, e.g.
    # "openshift-5.1" for an OCP component. When building the golang builder
    # image itself, __doozer_group=golang instead, which carries no OCP
    # version -- that, and any other group that doesn't match the expected
    # shape, is treated conservatively as pre-5.1.
    if [[ "${__doozer_group}" =~ ^openshift-([0-9]+)\.([0-9]+)$ ]]; then
      OCP_MAJOR="${BASH_REMATCH[1]}"
      OCP_MINOR="${BASH_REMATCH[2]}"
      if [[ "${OCP_MAJOR}" -gt 5 ]] || [[ "${OCP_MAJOR}" -eq 5 && "${OCP_MINOR}" -ge 1 ]]; then
        GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE=${GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE:-'.*'}
      fi
    fi
  fi
fi

# GO_BUILTIN_FIPS is set here, and only here, from GO_COMPLIANCE_BUILTIN_FIPS_
# INCLUDE/EXCLUDE. GO_BUILTIN_FIPS_AVAILABLE gates INCLUDE so that a component
# cannot opt in on a toolchain with no built-in module to opt into, even by
# explicitly configuring GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE -- there is no way
# to conjure one out of an older toolchain. EXCLUDE is the escape hatch for
# components that cannot use the built-in module yet; to fall back
# everywhere, set GO_COMPLIANCE_BUILTIN_FIPS_EXCLUDE='.*'.
GO_BUILTIN_FIPS="0"
if [[ "${GO_BUILTIN_FIPS_AVAILABLE}" == "1" && -n "${GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE}" > /dev/null; then
    echoerr "command matched GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE -- using the built-in FIPS module"
    GO_BUILTIN_FIPS="1"
  else
    echoerr "command did not match GO_COMPLIANCE_BUILTIN_FIPS_INCLUDE -- falling back to openssl"
  fi
fi

if [[ "${GO_BUILTIN_FIPS}" == "1" && -n "${GO_COMPLIANCE_BUILTIN_FIPS_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_BUILTIN_FIPS_EXCLUDE}" > /dev/null; then
    echoerr "command matched GO_COMPLIANCE_BUILTIN_FIPS_EXCLUDE -- falling back to openssl"
    GO_BUILTIN_FIPS="0"
  fi
fi

if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_cross_compile"* ]]; then
  if [[ -n "${GOARCH}" && "${FOUND_HOST_ARCH}" != *"${GOARCH}"* ]]; then
    echoerr "skipping forced compliance due to cross-compile ${FOUND_HOST_ARCH} vs ${GOARCH}"
    EXEMPT="1"
  fi
fi

if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_arch_${FOUND_HOST_ARCH}"* ]]; then
  echoerr "skipping forced compliance due to FOUND_HOST_ARCH=${FOUND_HOST_ARCH}"
  EXEMPT="1"
fi

if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_all"* ]]; then
  echoerr "skipping forced compliance due to broad exemption"
  EXEMPT="1"
fi

FORCE_CGO_ENABLED=1
if [[ -n "${GO_COMPLIANCE_CGO_ENABLED_INCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_CGO_ENABLED_INCLUDE}" > /dev/null; then
    FORCE_CGO_ENABLED="1"
  else
    FORCE_CGO_ENABLED="0"
  fi
fi

if [[ -n "${GO_COMPLIANCE_CGO_ENABLED_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_CGO_ENABLED_EXCLUDE}" > /dev/null; then
    FORCE_CGO_ENABLED="0"
  fi
fi

FORCE_DYNAMIC=1
if [[ -n "${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE}" > /dev/null; then
    FORCE_DYNAMIC="1"
  else
    FORCE_DYNAMIC="0"
  fi
fi

if [[ -n "${GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE}" > /dev/null; then
    FORCE_DYNAMIC="0"
  fi
fi

if [[ "${GO_BUILTIN_FIPS}" == "1" ]]; then
  # The built-in module is pure Go, so cgo is not needed to reach a compliant
  # backend. Since cgo is also what makes static linking fail, there is nothing
  # left to justify rewriting the caller's -extldflags either.
  FORCE_CGO_ENABLED="0"
  FORCE_DYNAMIC="0"
fi

FORCE_OPENSSL=1
if [[ -n "${GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE}" > /dev/null; then
    FORCE_OPENSSL="1"
  else
    FORCE_OPENSSL="0"
  fi
fi

if [[ -n "${GO_COMPLIANCE_OPENSSL_ENABLED_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_OPENSSL_ENABLED_EXCLUDE}" > /dev/null; then
    FORCE_OPENSSL="0"
  fi
fi

FORCE_FOD_MODE=1
if [[ -n "${GO_COMPLIANCE_FOD_MODE_INCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_FOD_MODE_INCLUDE}" > /dev/null; then
    FORCE_FOD_MODE="1"
  else
    FORCE_FOD_MODE="0"
  fi
fi

if [[ -n "${GO_COMPLIANCE_FOD_MODE_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_FOD_MODE_EXCLUDE}" > /dev/null; then
    FORCE_FOD_MODE="0"
  fi
fi

# Build tags the shim injects. These are orthogonal concerns: strictfipsruntime
# makes a binary die at startup on a FIPS host if it was not built against a
# compliant backend, whatever that backend is; no_openssl selects which backend.
SHIM_TAGS=""
if [[ "${FORCE_FOD_MODE}" == "1" ]]; then
  SHIM_TAGS="strictfipsruntime"
fi
if [[ "${GO_BUILTIN_FIPS}" == "1" ]]; then
  # Companion of GOFIPS140 below; together they select the built-in module.
  SHIM_TAGS="${SHIM_TAGS:+${SHIM_TAGS},}no_openssl"
fi

if [[ -n "${GO_COMPLIANCE_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_EXCLUDE}" > /dev/null; then
    echoerr "command matched GO_COMPLIANCE_EXCLUDE -- setting EXEMPT=\"1\""
    export EXEMPT="1"
  fi
fi

HAS_TAGS=0
if cat <<< "$@" | grep "\-tags" > /dev/null; then  # Note that go permits -tags or --tags
  HAS_TAGS="1"
fi

echoerr "EXEMPT: ${EXEMPT}"
if [[ "${EXEMPT}" != "1" ]]; then

  echoerr "not exempt: FORCE_CGO_ENABLED=\"${FORCE_CGO_ENABLED}\" FORCE_DYNAMIC=\"${FORCE_DYNAMIC}\" FORCE_OPENSSL=\"${FORCE_OPENSSL}\" FORCE_FOD_MODE=\"${FORCE_FOD_MODE}\" GO_BUILTIN_FIPS=\"${GO_BUILTIN_FIPS}\""

  IN_BUILD=0
  IN_RUN=0
  IN_TAGS=0
  COVERAGE_ADDED=0  # Track whether coverage_server.go has been added to the args
  ARGS=()  # We need to rebuild the argument list.
  for arg in "$@"; do

    if [[ "${arg}" == "run" ]]; then
      IN_RUN="1"
    fi

    # prior to detecting 'IN_RUN', grafana failed because it ran
    # 'go run build.go build' which caused the script to exec 'go run build.go build -tags strictfipsruntime'
    # 'go install ...' can also trigger builds. https://github.com/openshift/sriov-dp-admission-controller/blob/e7d954e5e287cca11ccce1684c54b2d170f0410d/scripts/build.sh#L32 .
    if [[ ( "${arg}" == "build" || "${arg}" == "install" ) && "${IN_RUN}" == "0" ]]; then
      # -tags apparently cannot come after a build path
      # e.g. "build ./cmd/cluster-openshift-apiserver-operator -tags strictfipsruntime" is invalid.
      # So, if we see "build" and no "-tags" ahead, then go ahead and force FOD tag.

      IN_BUILD="1"  # This is a go build invocation
      if [[ "${STRICT_MODE_FULL}" == "1" && "${GOEXPERIMENT}" != *"strictfipsruntime"* ]]; then
        stricterror
        exit 1
      fi

      ARGS+=("${arg}") # Add "build" or "install"

      if [[ "${GO_COMPLIANCE_COVER}" == "1" ]]; then
        echoerr "adding -cover for build or install operation"
        ARGS+=("-cover")
        ARGS+=("-covermode=atomic")
      fi

      if [[ -n "${SHIM_TAGS}" && "${HAS_TAGS}" == "0" ]]; then
        ARGS+=("-tags")
        ARGS+=("${SHIM_TAGS}")
      fi
      continue  # We've already added 'build' or 'install', so don't reach the bottom of the loop where it would be added again.
    fi

    if [[ ( "${arg}" == "-tags="* || "${arg}" == "--tags="* ) && -n "${SHIM_TAGS}" ]]; then
      echoerr "adding ${SHIM_TAGS} tags to \"${arg}\""
      arg=$(echo "${arg}" | tr -d "'" | tr -d "\"")  # Delete any quotes which get passed in literally. grafana managed this.
      if [[ "${arg}" == *" "* ]]; then  # If the tags parameter is space delimited
        arg="${arg} ${SHIM_TAGS//,/ }"
      else
        # Assume comma delimited
        arg="${arg},${SHIM_TAGS}"
      fi
    fi

    # A tag list reaches us in one of two spellings: attached to the flag as
    # "-tags=<list>" (handled here), or as the argument following a bare "-tags"
    # (handled by the IN_TAGS block below). Both have to be scrubbed, and the
    # scrub is independent of whether we are also adding tags of our own.
    # It is only relevant to the libopenssl backend though: from Go 1.26 the
    # built-in module supersedes it and no_openssl is asserted, not stripped.
    if [[ ( "${arg}" == "-tags="* || "${arg}" == "--tags="* ) && "${FORCE_OPENSSL}" == "1" && "${GO_BUILTIN_FIPS}" == "0" ]]; then
      scrub_no_openssl
    fi

    if [[ "${IN_TAGS}" == "1" ]]; then
      if [[ -n "${SHIM_TAGS}" ]]; then
        echoerr "adding ${SHIM_TAGS} tags to ${arg} (IN_TAGS=${IN_TAGS})"
        arg=$(echo "${arg}" | tr -d "'" | tr -d "\"")  # Delete any quotes which get passed in literally. prom-label-proxy managed this.
        if [[ "${arg}" == *" "* ]]; then  # If the tags parameter is space delimited
          arg="${arg} ${SHIM_TAGS//,/ }"
        else
          # Assume comma delimited
          arg="${arg},${SHIM_TAGS}"
        fi
      fi
      if [[ "${FORCE_OPENSSL}" == "1" && "${GO_BUILTIN_FIPS}" == "0" ]]; then
        scrub_no_openssl
      fi
      IN_TAGS=0
    fi

    if [[ "${arg}" == "-tags" || "${arg}" == "--tags" ]]; then
      IN_TAGS=1
    fi

    # Compilation with -extldflags "-static" is problematic with
    # CGO_ENABLED=1 because compilation tries to link against
    # static libraries which don't exist. Remove -static flag
    # when detected. This is tricky because extldflags can be simple
    # or something like -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-lm -lstdc++ -static"'
    # Note that extldflags is a flag embedded within the value of the
    # -ldflags argument. From our script's perspective, it will be part of a single
    # argument, but this argument might look like '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-lm -lstdc++ -static"'.
    if [[ "${arg}" == *"-extldflags"* && "${FORCE_DYNAMIC}" == "1" ]]; then
      # We replace -static with -lc because '-lc' implies to link against stdlib. This is a default
      # and should therefore be benign for virtually any compilation (unless -nostdlib or -nodefaultlibs
      # is specified -- and we don't account for this).
      # Why replace instead of remove? Consider the complex possible scenarios:
      # -ldflags '-extldflags "-static"'   # Removing -extldflags would mean we also need to remove ldflags.
      # -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-static"'  # Would remove extldflags but keep ldflags
      # -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-static -lm"'  # Would need to remove -static but keep extldflags
      # In any scenario, replacing "-static" with something benign should work without the need for complex logic.
      pre_arg="${arg}"
      arg=$(echo "${arg}" | sed "s/-static/-lc/g")
      if [[ "${pre_arg}" != "${arg}" ]]; then
        echoerr "non-compliant: eliminated static"
        if [[ "${STRICT_MODE_BASIC}" == "1" ]]; then
          stricterror
          exit 1
        fi
      fi
    fi
    ARGS+=("${arg}")

    # When coverage is enabled and explicit .go files are being compiled,
    # ensure coverage_server.go is included if it exists alongside them.
    # Package-path builds (e.g. ./cmd/...) don't need this since Go
    # automatically includes all .go files in the package.
    if [[ "${GO_COMPLIANCE_COVER}" == "1" && "${IN_BUILD}" == "1" && "${COVERAGE_ADDED}" == "0" && "${arg}" == *.go ]]; then
      if [[ "$(basename "${arg}")" == "coverage_server.go" ]]; then
        COVERAGE_ADDED=1
      else
        coverage_path="$(dirname "${arg}")/coverage_server.go"
        if [[ -f "${coverage_path}" ]]; then
          echoerr "adding ${coverage_path} to build for coverage instrumentation"
          ARGS+=("${coverage_path}")
          COVERAGE_ADDED=1
        fi
      fi
    fi
  done

  if [[ "${FORCE_CGO_ENABLED}" == "1" && "${IN_BUILD}" == "1" ]]; then
      if [[ "${CGO_ENABLED}" == "0" ]]; then
        echoerr "non-compliant: had to turn on CGO_ENABLED"
        if [[ "${STRICT_MODE_BASIC}" == "1" ]]; then
          stricterror
          exit 1
        fi
      fi
      export CGO_ENABLED="1"
      echoerr "setting CGO_ENABLED=${CGO_ENABLED}"
  fi

  if [[ "${FORCE_FOD_MODE}" == "1" && "${GOEXPERIMENT}" != *"strictfipsruntime"* ]]; then
    if [[ -n "${GOEXPERIMENT}" ]]; then
      export GOEXPERIMENT="strictfipsruntime,${GOEXPERIMENT}"
    else
      export GOEXPERIMENT="strictfipsruntime"
    fi
    echoerr "setting GOEXPERIMENT=${GOEXPERIMENT}"
  fi

  # Companion of the no_openssl tag: together they select the built-in module.
  if [[ "${GO_BUILTIN_FIPS}" == "1" ]]; then
    export GOFIPS140="v1.26.0"
    echoerr "setting GOFIPS140=${GOFIPS140}"
  fi

fi

if [[ "${GO_COMPLIANCE_INFO}" == "1" ]]; then
  echo 1>&2
  echo 1>&2
  echo -n "${LOG_PREFIX} final command line arguments: " 1>&2
  for arg in "${ARGS[@]}"; do
    echo -n "\"${arg}\" " 1>&2
  done
  echo 1>&2
  echo 1>&2
fi

run_go "${ARGS[@]}"

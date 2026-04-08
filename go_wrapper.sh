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

run_go() {
  if [[ "${SHIM_TEST}" == "1" ]]; then
    echoerr "running with SHIM_TEST=${SHIM_TEST}"
    echo -n "GOEXPERIMENT=${GOEXPERIMENT} CGO_ENABLED=${CGO_ENABLED} "
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
GO_COMPLIANCE_COVER=${GO_COMPLIANCE_COVER:-'0'}

if [[ -n "${OPENSHIFT_CI}" || "${__doozer_group}" == "openshift-"* ]]; then
  GO_COMPLIANCE_POLICY="${GO_COMPLIANCE_POLICY:-exempt_darwin,exempt_windows,exempt_cross_compile}"
  export GOTOOLCHAIN="local"
  echoerr "Forcing GOTOOLCHAIN=${GOTOOLCHAIN}"
else
  GO_COMPLIANCE_POLICY="exempt_all"
fi

if [[ "${GO_COMPLIANCE_DEBUG}" == "1" ]]; then
  echoerr "config GO_COMPLIANCE_POLICY=\"${GO_COMPLIANCE_POLICY}\" GO_COMPLIANCE_CGO_ENABLED_INCLUDE=\"${GO_COMPLIANCE_CGO_ENABLED_INCLUDE}\" GO_COMPLIANCE_CGO_ENABLED_EXCLUDE=\"${GO_COMPLIANCE_CGO_ENABLED_EXCLUDE}\" GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE=\"${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE}\" GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE=\"${GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE}\" GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE=\"${GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE}\" GO_COMPLIANCE_OPENSSL_ENABLED_EXCLUDE=\"${GO_COMPLIANCE_OPENSSL_ENABLED_EXCLUDE}\" GO_COMPLIANCE_FOD_MODE_INCLUDE=\"${GO_COMPLIANCE_FOD_MODE_INCLUDE}\" GO_COMPLIANCE_FOD_MODE_EXCLUDE=\"${GO_COMPLIANCE_FOD_MODE_EXCLUDE}\""

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
else
  FOUND_HOST_ARCH="$(go.real env GOHOSTARCH)"
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

  echoerr "not exempt: FORCE_CGO_ENABLED=\"${FORCE_CGO_ENABLED}\" FORCE_DYNAMIC=\"${FORCE_DYNAMIC}\" FORCE_OPENSSL=\"${FORCE_OPENSSL}\" FORCE_FOD_MODE=\"${FORCE_FOD_MODE}\""

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

      if [[ "${FORCE_FOD_MODE}" == "1" && "${HAS_TAGS}" == "0" ]]; then
        ARGS+=("-tags")
        ARGS+=("strictfipsruntime")
      fi
      continue  # We've already added 'build' or 'install', so don't reach the bottom of the loop where it would be added again.
    fi

    if [[ ( "${arg}" == "-tags="* || "${arg}" == "--tags="* ) && "${FORCE_FOD_MODE}" == "1" ]]; then
      echoerr "adding strictfipsruntime tag to \"${arg}\""
      arg=$(echo "${arg}" | tr -d "'" | tr -d "\"")  # Delete any quotes which get passed in literally. grafana managed this.
      if [[ "${arg}" == *" "* ]]; then  # If the tags parameter is space delimited
        arg="${arg} strictfipsruntime"
      else
        # Assume comma delimited
        arg="${arg},strictfipsruntime"
      fi
    fi

    if [[ "${IN_TAGS}" == "1" ]]; then
      if [[ "${FORCE_FOD_MODE}" == "1" ]]; then
        echoerr "adding strictfipsruntime tag to ${arg} (IN_TAGS=${IN_TAGS})"
        arg=$(echo "${arg}" | tr -d "'" | tr -d "\"")  # Delete any quotes which get passed in literally. prom-label-proxy managed this.
        if [[ "${arg}" == *" "* ]]; then  # If the tags parameter is space delimited
          arg="${arg} strictfipsruntime"
        else
          # Assume comma delimited
          arg="${arg},strictfipsruntime"
        fi
      fi
      if [[ "${FORCE_OPENSSL}" == "1" ]]; then
        pre_arg="${arg}"
        arg=$(echo "${arg}" | sed 's/no_openssl/shim_prevented_no_openssl/g')
        if [[ "${pre_arg}" != "${arg}" ]]; then
          echoerr "non-compliant: eliminated no_openssl"
          if [[ "${STRICT_MODE_BASIC}" == "1" ]]; then
            stricterror
            exit 1
          fi
        fi
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
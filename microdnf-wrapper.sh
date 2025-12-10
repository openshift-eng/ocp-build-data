#!/usr/bin/env bash
# Wrapper for microdnf that removes unsupported dnf options.

# Allowed setopt options for microdnf
ALLOWED_SETOPTS=(
    "tsflags"
    "keepcache"
    "install_weak_deps"
)

# Normalize boolean values (false/False => 0, true/True => 1)
normalize_boolean() {
    local value="$1"
    case "$value" in
        true|True)
            echo "1"
            ;;
        false|False)
            echo "0"
            ;;
        *)
            echo "$value"
            ;;
    esac
}

# Check if a setopt option is allowed
is_allowed_setopt() {
    local option="$1"
    # Extract the option name (before the = sign)
    local opt_name="${option%%=*}"

    for allowed in "${ALLOWED_SETOPTS[@]}"; do
        if [[ "$opt_name" == "$allowed" ]]; then
            return 0
        fi
    done
    return 1
}

# Build a filtered argument list
args=()
skip_next=false
pending_setopt=false

for arg in "$@"; do
    # Handle the value after a standalone --setopt
    if $pending_setopt; then
        pending_setopt=false
        if is_allowed_setopt "$arg"; then
            # Normalize boolean values in the option
            opt_name="${arg%%=*}"
            opt_value="${arg#*=}"
            normalized_value=$(normalize_boolean "$opt_value")
            args+=("--setopt" "${opt_name}=${normalized_value}")
        fi
        continue
    fi

    # Skip arguments flagged to skip
    if $skip_next; then
        skip_next=false
        continue
    fi

    case "$arg" in
        --setopt=*)
            # Handle '--setopt=foo=bar' format
            setopt_value="${arg#--setopt=}"
            if is_allowed_setopt "$setopt_value"; then
                # Normalize boolean values in the option
                opt_name="${setopt_value%%=*}"
                opt_value="${setopt_value#*=}"
                normalized_value=$(normalize_boolean "$opt_value")
                args+=("--setopt=${opt_name}=${normalized_value}")
            fi
            ;;
        --setopt)
            # Handle '--setopt foo=bar' format (two arguments)
            pending_setopt=true
            ;;
        --exclude*)
            # Handles '--exclude=foo' and '--exclude foo'
            [[ "$arg" == --exclude ]] && skip_next=true
            continue
            ;;
        --allowerasing)
            # microdnf doesn't support --allowerasing, skip it
            continue
            ;;
        *)
            args+=("$arg")
            ;;
    esac
done

# Execute microdnf with the cleaned arguments
exec /usr/bin/microdnf "${args[@]}"

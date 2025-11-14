#!/usr/bin/env bash
# Wrapper for microdnf that removes unsupported dnf options.

# Build a filtered argument list
args=()
skip_next=false

for arg in "$@"; do
    if $skip_next; then
        skip_next=false
        continue
    fi

    case "$arg" in
        --setopt*)
            # Handles both '--setopt=foo=bar' and '--setopt foo=bar'
            [[ "$arg" == --setopt ]] && skip_next=true
            continue
            ;;
        *)
            args+=("$arg")
            ;;
    esac
done

# Execute microdnf with the cleaned arguments
exec /usr/bin/microdnf "${args[@]}"

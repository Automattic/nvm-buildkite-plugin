#!/usr/bin/env bash

# Sourced helper only, so no set options. Up to callers to set strict mode before loading it.
#
# nvm walks PWD with slash trimming, Windows paths can make that loop forever.
# These helpers allow preventing that behavior.

nvm_plugin_should_normalize_windows_pwd() {
    local shell_name="$1"
    local current_pwd="$2"

    case "$shell_name" in
        CYGWIN* | MINGW* | MSYS*) ;;
        *) return 1 ;;
    esac

    case "$current_pwd" in
        *\\* | ?:*) return 0 ;;
        *) return 1 ;;
    esac
}

nvm_plugin_windows_pwd_to_posix() {
    local current_pwd="$1"
    local drive
    local drive_lower
    local rest

    case "$current_pwd" in
        [A-Za-z]:*)
            drive="${current_pwd:0:1}"
            drive_lower="$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')"
            rest="${current_pwd:2}"
            rest="${rest//\\//}"

            printf '/%s%s\n' "$drive_lower" "$rest"
            return 0
            ;;
        \\\\*)
            printf '%s\n' "${current_pwd//\\//}"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

nvm_plugin_normalize_windows_pwd_for_nvm() {
    local shell_name
    shell_name="$(uname -s 2>/dev/null || true)"

    if ! nvm_plugin_should_normalize_windows_pwd "$shell_name" "${PWD:-}"; then
        return 0
    fi

    local normalized_pwd
    if ! normalized_pwd="$(nvm_plugin_windows_pwd_to_posix "$PWD")"; then
        echo "Cannot normalize Windows PWD for nvm from ${PWD}"
        return 0
    fi

    if [[ -z "$normalized_pwd" || "$normalized_pwd" == "$PWD" ]]; then
        echo "Cannot normalize Windows PWD for nvm from ${PWD}"
        return 0
    fi

    if [[ ! -d "$normalized_pwd" ]]; then
        echo "Cannot normalize Windows PWD for nvm because ${normalized_pwd} is not a directory"
        return 0
    fi

    echo "Normalizing Windows PWD for nvm from ${PWD} to ${normalized_pwd}"
    cd "$normalized_pwd" || {
        echo "Failed to normalize Windows PWD for nvm to ${normalized_pwd}"
        return 0
    }
}

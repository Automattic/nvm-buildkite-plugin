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

# Echoes the POSIX directory nvm should run in for the given shell and PWD.
# Returns 0 with no output when no normalization is needed. Returns non-zero
# when the PWD needs normalizing but a usable target can't be produced — the
# caller must treat that as fatal, since letting nvm run on the un-normalized
# PWD is the hang this helper exists to avoid.
nvm_plugin_resolve_normalized_pwd() {
    local shell_name="$1"
    local current_pwd="$2"

    nvm_plugin_should_normalize_windows_pwd "$shell_name" "$current_pwd" || return 0

    local normalized_pwd
    normalized_pwd="$(nvm_plugin_windows_pwd_to_posix "$current_pwd")" || return 1
    [[ -n "$normalized_pwd" && "$normalized_pwd" != "$current_pwd" ]] || return 1
    [[ -d "$normalized_pwd" ]] || return 1

    printf '%s\n' "$normalized_pwd"
}

nvm_plugin_normalize_windows_pwd_for_nvm() {
    local shell_name current_pwd
    shell_name="$(uname -s 2>/dev/null || true)"
    current_pwd="${PWD:-}"

    local normalized_pwd
    if ! normalized_pwd="$(nvm_plugin_resolve_normalized_pwd "$shell_name" "$current_pwd")"; then
        echo "Cannot normalize Windows PWD for nvm from ${current_pwd}; refusing to continue so nvm does not hang" >&2
        return 1
    fi

    [[ -n "$normalized_pwd" ]] || return 0

    echo "Normalizing Windows PWD for nvm from ${current_pwd} to ${normalized_pwd}"
    cd "$normalized_pwd" || {
        echo "Cannot enter normalized Windows PWD ${normalized_pwd} for nvm; refusing to continue so nvm does not hang" >&2
        return 1
    }
}

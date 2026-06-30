#!/usr/bin/env bash

# Sourced helper only; callers set strict mode before loading it.
# nvm walks PWD with slash trimming; Windows paths can make that loop forever.

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

nvm_plugin_normalize_windows_pwd_for_nvm() {
    local shell_name
    shell_name="$(uname -s 2>/dev/null || true)"

    if ! nvm_plugin_should_normalize_windows_pwd "$shell_name" "${PWD:-}"; then
        return 0
    fi

    if ! command -v cygpath >/dev/null 2>&1; then
        echo "Cannot normalize Windows PWD for nvm because cygpath is not available"
        return 0
    fi

    local normalized_pwd
    normalized_pwd="$(cygpath -u "$PWD" 2>/dev/null || true)"

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

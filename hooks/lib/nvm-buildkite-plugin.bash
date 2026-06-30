#!/usr/bin/env bash

nvm_plugin_read_seconds() {
    local env_name="$1"
    local default_value="$2"
    local label="$3"
    local value="${!env_name:-$default_value}"

    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        echo "Invalid ${label}: ${value}. Expected a non-negative integer." >&2
        return 1
    fi

    echo "$value"
}

nvm_plugin_timestamp() {
    date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || echo "unknown-time"
}

nvm_plugin_log() {
    printf '[nvm-buildkite-plugin] %s %s\n' "$(nvm_plugin_timestamp)" "$*"
}

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

    # nvm walks PWD with slash trimming; Windows paths can make that loop forever.
    echo "Normalizing Windows PWD for nvm from ${PWD} to ${normalized_pwd}"
    cd "$normalized_pwd" || {
        echo "Failed to normalize Windows PWD for nvm to ${normalized_pwd}"
        return 0
    }
}

nvm_plugin_descendant_pids() {
    local root_pid="$1"

    if [[ -z "$root_pid" ]] || ! command -v ps >/dev/null 2>&1; then
        return 0
    fi

    ps -ef 2>/dev/null | awk -v root_pid="$root_pid" '
        NR > 1 {
            pid = $2
            ppid = $3
            children[ppid] = children[ppid] " " pid
        }

        function print_descendants(parent, descendants, child_index, child) {
            split(children[parent], descendants, " ")
            for (child_index in descendants) {
                child = descendants[child_index]
                if (child != "") {
                    print child
                    print_descendants(child)
                }
            }
        }

        END {
            print_descendants(root_pid)
        }
    ' || true
}

nvm_plugin_terminate_process_tree() {
    local description="$1"
    local command_pid="$2"
    local descendant_pids=""
    local remaining_descendant_pids=""

    descendant_pids="$(nvm_plugin_descendant_pids "$command_pid" | tr '\n' ' ')"
    nvm_plugin_log "${description} descendant pids before SIGTERM: ${descendant_pids:-none}" >&2
    nvm_plugin_log "Sending SIGTERM to ${description} pid=${command_pid}" >&2

    if [[ -n "$descendant_pids" ]]; then
        # shellcheck disable=SC2086
        kill -TERM $descendant_pids 2>/dev/null || true
    fi

    kill -TERM "$command_pid" 2>/dev/null || true
    sleep 10

    remaining_descendant_pids="$(nvm_plugin_descendant_pids "$command_pid" | tr '\n' ' ')"
    nvm_plugin_log "${description} descendant pids before SIGKILL: ${remaining_descendant_pids:-none}" >&2
    nvm_plugin_log "Sending SIGKILL to ${description} pid=${command_pid}" >&2

    if [[ -n "$remaining_descendant_pids" ]]; then
        # shellcheck disable=SC2086
        kill -KILL $remaining_descendant_pids 2>/dev/null || true
    fi

    kill -KILL "$command_pid" 2>/dev/null || true
}

nvm_plugin_run_with_timeout() {
    local description="$1"
    local timeout_seconds="$2"
    local heartbeat_seconds="$3"
    shift 3

    if [[ "$timeout_seconds" == "0" && "$heartbeat_seconds" == "0" ]]; then
        nvm_plugin_log "Running ${description} without timeout or heartbeat"
        "$@"
        return
    fi

    nvm_plugin_log "Starting ${description}; timeout=${timeout_seconds}s heartbeat=${heartbeat_seconds}s"
    "$@" &
    local command_pid="$!"
    local start_seconds="$SECONDS"
    local elapsed_seconds=0
    local next_heartbeat_seconds="$heartbeat_seconds"
    nvm_plugin_log "${description} pid=${command_pid}"

    while kill -0 "$command_pid" 2>/dev/null; do
        elapsed_seconds=$((SECONDS - start_seconds))

        if [[ "$timeout_seconds" != "0" && "$elapsed_seconds" -ge "$timeout_seconds" ]]; then
            echo "ERROR: ${description} timed out after ${timeout_seconds}s" >&2
            nvm_plugin_terminate_process_tree "$description" "$command_pid"
            break
        fi

        if [[ "$heartbeat_seconds" != "0" && "$elapsed_seconds" -ge "$next_heartbeat_seconds" ]]; then
            nvm_plugin_log "${description} still running after ${elapsed_seconds}s; pid=${command_pid}"
            next_heartbeat_seconds=$((next_heartbeat_seconds + heartbeat_seconds))
        fi

        sleep 1
    done

    local status=0
    if wait "$command_pid"; then
        status=0
    else
        status="$?"
    fi

    elapsed_seconds=$((SECONDS - start_seconds))
    nvm_plugin_log "${description} exited with status ${status} after ${elapsed_seconds}s"

    return "$status"
}

nvm_plugin_run_nvm_install_with_timeout() {
    local timeout_seconds="$1"
    local heartbeat_seconds="$2"
    shift 2

    # shellcheck disable=SC2016
    nvm_plugin_run_with_timeout "nvm install" "$timeout_seconds" "$heartbeat_seconds" bash -c '
set -e
source "$NVM_DIR/nvm.sh" --no-use
nvm install "$@"
' nvm-install "$@"
}

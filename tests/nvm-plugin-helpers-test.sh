#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=hooks/lib/nvm-buildkite-plugin.bash
source "$repo_root/hooks/lib/nvm-buildkite-plugin.bash"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

nvm_plugin_should_normalize_windows_pwd "MSYS_NT-10.0" 'C:\buildkite-agent\repo' || fail "MSYS backslash PWD should be normalized"
nvm_plugin_should_normalize_windows_pwd "CYGWIN_NT-10.0" 'C:/buildkite-agent/repo' || fail "Cygwin drive PWD should be normalized"

if nvm_plugin_should_normalize_windows_pwd "MSYS_NT-10.0" "/c/buildkite-agent/repo"; then
    fail "MSYS POSIX PWD should not be normalized"
fi

if nvm_plugin_should_normalize_windows_pwd "linux-gnu" 'C:\buildkite-agent\repo'; then
    fail "non-Windows shell PWD should not be normalized"
fi

echo "All helper tests passed."

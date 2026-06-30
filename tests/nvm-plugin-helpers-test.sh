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

[[ "$(nvm_plugin_windows_pwd_to_posix 'C:\buildkite-agent\repo')" == "/c/buildkite-agent/repo" ]] || fail "backslash drive path should convert to POSIX path"
[[ "$(nvm_plugin_windows_pwd_to_posix 'D:/buildkite-agent/repo')" == "/d/buildkite-agent/repo" ]] || fail "slash drive path should convert to POSIX path"
[[ "$(nvm_plugin_windows_pwd_to_posix '\\server\share\repo')" == "//server/share/repo" ]] || fail "UNC path should convert to POSIX path"

if nvm_plugin_windows_pwd_to_posix "/c/buildkite-agent/repo" >/dev/null; then
    fail "POSIX path should not be converted"
fi

echo "All helper tests passed."

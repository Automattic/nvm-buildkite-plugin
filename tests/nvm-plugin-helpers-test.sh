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

# nvm_plugin_resolve_normalized_pwd: no normalization needed -> success, no output.
[[ -z "$(nvm_plugin_resolve_normalized_pwd "linux-gnu" 'C:\buildkite-agent\repo')" ]] || fail "non-Windows shell should resolve to no normalization"
[[ -z "$(nvm_plugin_resolve_normalized_pwd "MSYS_NT-10.0" "/c/buildkite-agent/repo")" ]] || fail "POSIX PWD should resolve to no normalization"

# A PWD that needs normalizing and points at a real directory resolves to it.
# The input is the tmp dir as a UNC path: a leading "\\" plus the dir with its
# slashes flipped to backslashes, which nvm_plugin_windows_pwd_to_posix converts back.
real_dir="$(mktemp -d)"
trap 'rm -rf "$real_dir"' EXIT
resolved="$(nvm_plugin_resolve_normalized_pwd "MSYS_NT-10.0" "\\${real_dir//\//\\}")" || fail "resolvable Windows PWD should not fail"
[[ -n "$resolved" && -d "$resolved" ]] || fail "resolvable Windows PWD should be normalized to an existing directory"

# A PWD that needs normalizing but cannot be resolved must fail, not fall through.
if nvm_plugin_resolve_normalized_pwd "MSYS_NT-10.0" 'relative\path' >/dev/null; then
    fail "unconvertible Windows PWD should fail rather than resolve"
fi
if nvm_plugin_resolve_normalized_pwd "MSYS_NT-10.0" 'C:\does\not\exist' >/dev/null; then
    fail "Windows PWD pointing at a missing directory should fail rather than resolve"
fi

echo "All helper tests passed."

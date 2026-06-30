#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=hooks/lib/nvm-buildkite-plugin.bash
source "$repo_root/hooks/lib/nvm-buildkite-plugin.bash"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_equals() {
    local expected="$1"
    local actual="$2"

    [[ "$actual" == "$expected" ]] || fail "expected '$expected', got '$actual'"
}

assert_contains() {
    local needle="$1"
    local file="$2"

    grep -F "$needle" "$file" >/dev/null || fail "expected '$file' to contain '$needle'"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

assert_equals 1800 "$(nvm_plugin_read_seconds MISSING_TIMEOUT 1800 install-timeout-seconds)"

nvm_plugin_should_normalize_windows_pwd "MSYS_NT-10.0" 'C:\buildkite-agent\repo' || fail "MSYS backslash PWD should be normalized"
nvm_plugin_should_normalize_windows_pwd "CYGWIN_NT-10.0" 'C:/buildkite-agent/repo' || fail "Cygwin drive PWD should be normalized"

if nvm_plugin_should_normalize_windows_pwd "MSYS_NT-10.0" "/c/buildkite-agent/repo"; then
    fail "MSYS POSIX PWD should not be normalized"
fi

if nvm_plugin_should_normalize_windows_pwd "linux-gnu" 'C:\buildkite-agent\repo'; then
    fail "non-Windows shell PWD should not be normalized"
fi

export BUILDKITE_PLUGIN_NVM_INSTALL_TIMEOUT_SECONDS=12
assert_equals 12 "$(nvm_plugin_read_seconds BUILDKITE_PLUGIN_NVM_INSTALL_TIMEOUT_SECONDS 1800 install-timeout-seconds)"

export BUILDKITE_PLUGIN_NVM_INSTALL_TIMEOUT_SECONDS=abc
if nvm_plugin_read_seconds BUILDKITE_PLUGIN_NVM_INSTALL_TIMEOUT_SECONDS 1800 install-timeout-seconds >"$tmpdir/invalid.out" 2>"$tmpdir/invalid.err"; then
    fail "invalid timeout value should fail"
fi
assert_contains "Invalid install-timeout-seconds" "$tmpdir/invalid.err"
unset BUILDKITE_PLUGIN_NVM_INSTALL_TIMEOUT_SECONDS

mkdir -p "$tmpdir/fake-bin"
cat > "$tmpdir/fake-bin/ps" <<'PS'
#!/usr/bin/env bash
if [[ "$*" == "-ef" ]]; then
    cat <<'OUTPUT'
UID        PID  PPID  C STIME TTY          TIME CMD
buildkit   100     1  0 00:00 ?        00:00:00 /usr/bin/bash hook
buildkit   101   100  0 00:00 ?        00:00:00 /usr/bin/bash child
buildkit   102   101  0 00:00 ?        00:00:00 /usr/bin/bash grandchild
buildkit   103   100  0 00:00 ?        00:00:00 /usr/bin/curl download
buildkit   200     1  0 00:00 ?        00:00:00 /usr/bin/bash unrelated
OUTPUT
else
    exit 1
fi
PS
chmod +x "$tmpdir/fake-bin/ps"

PATH="$tmpdir/fake-bin:$PATH" nvm_plugin_descendant_pids 100 >"$tmpdir/descendants.out"
assert_contains "101" "$tmpdir/descendants.out"
assert_contains "102" "$tmpdir/descendants.out"
assert_contains "103" "$tmpdir/descendants.out"
if grep -F "200" "$tmpdir/descendants.out" >/dev/null; then
    fail "descendant pids should not include unrelated processes"
fi

(
    kill() {
        echo "kill $*" >> "$tmpdir/kill.log"
    }

    sleep() {
        echo "sleep $*" >> "$tmpdir/sleep.log"
    }

    PATH="$tmpdir/fake-bin:$PATH" nvm_plugin_terminate_process_tree "fake command" 100 >"$tmpdir/terminate.out" 2>"$tmpdir/terminate.err"
)
assert_contains "fake command descendant pids before SIGTERM" "$tmpdir/terminate.err"
assert_contains "fake command descendant pids before SIGKILL" "$tmpdir/terminate.err"
assert_contains "kill -TERM" "$tmpdir/kill.log"
assert_contains "kill -KILL" "$tmpdir/kill.log"
assert_contains "100" "$tmpdir/kill.log"
assert_contains "101" "$tmpdir/kill.log"
assert_contains "102" "$tmpdir/kill.log"
assert_contains "103" "$tmpdir/kill.log"

if ! nvm_plugin_run_with_timeout "quick command" 5 0 bash -c 'exit 0'; then
    fail "quick command should pass"
fi

if nvm_plugin_run_with_timeout "slow command" 1 0 bash -c 'sleep 10' >"$tmpdir/timeout.out" 2>"$tmpdir/timeout.err"; then
    fail "slow command should time out"
fi
assert_contains "slow command timed out after 1s" "$tmpdir/timeout.err"

nvm_plugin_run_with_timeout "heartbeat command" 5 1 bash -c 'sleep 2' >"$tmpdir/heartbeat.out"
assert_contains "heartbeat command still running after 1s" "$tmpdir/heartbeat.out"

unset -f nvm 2>/dev/null || true
mkdir -p "$tmpdir/fake-nvm"
cat > "$tmpdir/fake-nvm/nvm.sh" <<'NVM'
nvm() {
    case "$1" in
        install)
            shift
            echo "fake child nvm install $*"
            touch "$NVM_DIR/installed"
            ;;
        *)
            echo "unsupported nvm command: $*" >&2
            return 1
            ;;
    esac
}
NVM

export NVM_DIR="$tmpdir/fake-nvm"
nvm_plugin_run_nvm_install_with_timeout 5 0 --no-progress 20.19.5 >"$tmpdir/child-install.out"
assert_contains "fake child nvm install --no-progress 20.19.5" "$tmpdir/child-install.out"
[[ -f "$tmpdir/fake-nvm/installed" ]] || fail "child nvm install should create installed marker"

unset NVM_DIR

echo "All helper tests passed."

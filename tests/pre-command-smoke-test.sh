#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin" "$tmpdir/work"

cat > "$tmpdir/bin/curl" <<'CURL'
#!/usr/bin/env bash
cat <<'INSTALLER'
#!/usr/bin/env bash
mkdir -p "$NVM_DIR"
cat > "$NVM_DIR/nvm.sh" <<'NVM'
nvm() {
    case "$1" in
        install)
            echo "fake nvm install ${*:2}"
            ;;
        use)
            echo "fake nvm use ${*:2}"
            ;;
        *)
            echo "unsupported nvm command: $*" >&2
            return 1
            ;;
    esac
}
NVM
INSTALLER
CURL
chmod +x "$tmpdir/bin/curl"

cat > "$tmpdir/bin/node" <<'NODE'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
    echo "v20.19.5"
elif [[ "${1:-}" == "-" ]]; then
    cat >/dev/null
    echo "Hello Node.js"
else
    echo "unsupported node command: $*" >&2
    exit 1
fi
NODE
chmod +x "$tmpdir/bin/node"

echo "20.19.5" > "$tmpdir/work/.nvmrc"

(
    export PATH="$tmpdir/bin:$PATH"
    export BUILDKITE_JOB_ID="pre-command-smoke"
    export BUILDKITE_PLUGIN_NVM_INSTALL_TIMEOUT_SECONDS=5
    export BUILDKITE_PLUGIN_NVM_HEARTBEAT_SECONDS=0
    export TMPDIR="$tmpdir/tmp"
    mkdir -p "$TMPDIR"

    cd "$tmpdir/work"
    bash "$repo_root/hooks/pre-command"
) > "$tmpdir/pre-command.out"

grep -F "fake nvm install --no-progress" "$tmpdir/pre-command.out" >/dev/null
grep -F "fake nvm use" "$tmpdir/pre-command.out" >/dev/null
grep -F "Node.js and nvm successfully set up." "$tmpdir/pre-command.out" >/dev/null

echo "pre-command smoke test passed."

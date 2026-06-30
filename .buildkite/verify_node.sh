#!/bin/bash

set -euo pipefail

echo "--- :node: Current Node.js version is $(node --version)"

echo "NVM_DIR is: $NVM_DIR"

# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh" --no-use

echo "Checking if the active Node.js version is '$1'"

expected_version=$(nvm version-remote "$1")
echo "'$1' is resolved to the Node.js version $expected_version"

# On Windows, `nvm current` reports `system` after `--no-use`; PATH has the real version.
case "$(uname -s 2>/dev/null || true)" in
    CYGWIN* | MINGW* | MSYS*)
        current_version=$(node --version)
        echo "Current node executable version is $current_version"
        ;;
    *)
        current_version=$(nvm current)
        echo "Currently activated Node.js version is $current_version"
        ;;
esac

test "$current_version" == "$expected_version"

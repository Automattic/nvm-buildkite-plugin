#!/bin/bash

set -euo pipefail

echo "--- :node: Current Node.js version is $(node --version)"

echo "NVM_DIR is: $NVM_DIR"
echo "NVM_BIN is: ${NVM_BIN:-unset}"
echo "node path is: $(command -v node)"

# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh" --no-use

echo "Checking if the active Node.js version is '$1'"

expected_version=$(nvm version-remote "$1")
echo "'$1' is resolved to the Node.js version $expected_version"

current_node_version=$(node --version)
echo "Current node executable version is $current_node_version"

test "$current_node_version" == "$expected_version"

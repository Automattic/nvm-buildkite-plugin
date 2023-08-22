#!/bin/bash

set -euo pipefail

echo "--- :node: Current node version is $(node --version)"

echo "NVM_DIR is: $NVM_DIR"

# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh" --no-use

echo "Checking if the active node version is '$1'"

expected_version=$(nvm version-remote "$1")
echo "'$1' is resolved to the node version $expected_version"

current_version=$(nvm current)
echo "Currently activated node version is $current_version"

test "$current_version" == "$expected_version"

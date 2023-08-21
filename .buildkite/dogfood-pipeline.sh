#!/bin/bash

set -euo pipefail

pipeline_step() {
    node_version=$1
    pipeline_yml=$2
    {
        echo "  - label: ':node: Validate $node_version'"
        echo "    command: .buildkite/verify_node.sh '$node_version'"
        echo "    plugins:"
        echo "      - ./:"
        echo "          version: '$node_version'"
    } >> "$pipeline_yml"
}

pipeline_file=".buildkite/dogfood-pipeline.yml"
echo "steps:" > "$pipeline_file"

for version in "$@"; do
    pipeline_step "$version" "$pipeline_file"
done

echo "--- :pipeline: Generated pipeline file"
cat "$pipeline_file"

if [[ "${BUILDKITE:-}" == "true" ]]; then
    echo "--- :pipeline: Uploading pipeline"
    buildkite-agent pipeline upload "$pipeline_file"
fi

#!/bin/bash
set -e

WORK_DIR='./repos'

echo "## Outdated api(s) dependencies"

for repo in "$WORK_DIR/"*/ ; do
    if [[ $repo =~ "lib-common" ]]; then
        continue
    fi
    repo_name=$(echo "$repo" | cut -d '/' -f3)
    echo "### $repo_name"
    MOD_FILE="$repo/go.mod" ./check_deps.sh || true
    echo "---"
done

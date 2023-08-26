#!/bin/bash
set -e

WORK_DIR='./repos'

for repo in "$WORK_DIR/"*/ ; do
    if [[ $repo =~ "lib-common" ]];
    then
        continue
    fi
    echo "Checking $repo"
    MOD_FILE="$repo/go.mod" ./check_deps.sh || true
    echo "---"
done


#!/bin/bash

set -e
out=OperatorDependencyBumpOrder.md

rm -rf ./repos
./setup_repos.sh

echo "# Operator dependency order" > $out
./generate_bump_ordering.py > $out

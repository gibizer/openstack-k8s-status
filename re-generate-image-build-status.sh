#!/bin/bash

set -e
out=ImageBuildStatus.md

echo "# Post merge image build status" > $out

while read -r repo; do
    name=$(echo "$repo"| cut -d '/' -f3)
    if [ $name = "lib-common" ]; then
            continue
    fi
    url="https://github.com/openstack-k8s-operators/$name/actions/workflows"
    img_link="[$name image builder]($url/build-$name.yaml/badge.svg)]"
    echo "* [!$img_link($url/build-$name.yaml)" >> $out
done < repo_list.txt

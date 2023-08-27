#!/bin/bash
set -ex

source ./lib.sh

clone_all() {

    while read -r repo;
    do
        name=$(echo "$repo"| cut -d '/' -f3)
        clone_repo "http://$repo" "$WORK_DIR/$name"
    done < repo_list.txt

}

WORK_DIR='./repos'

rm -rf "${WORK_DIR:?}"/*
clone_all
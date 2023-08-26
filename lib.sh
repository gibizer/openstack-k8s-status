#!/bin/bash
set -e

clone_repo() {
    local repo_url=$1
    local to=$2

    git clone -q "${repo_url}" "${to}"
}

#!/bin/bash
set -e

source ./lib.sh

newer_significant_commits() {
    local go_mod_line=$1
    local branch=$2

    local dep=$(echo ${go_mod_line} | cut -d' ' -f1)
    local version=$(echo ${go_mod_line} | cut -d' ' -f2)

    local org=$(echo ${dep} | cut -d'/' -f-2)
    local repo_name=$(echo ${dep} | cut -d'/' -f3)
    local dep_api_dir=$(echo ${dep} | cut -d'/' -f4)
    local repo_url="http://${org}/${repo_name}"

    local hash=$(echo ${version} | cut -d'-' -f3)

    local local="${WORK_DIR}/${repo_name}"

    clone_repo ${repo_url} ${local}

    pushd ${local} > /dev/null

    newer_commits=$(git log --no-merges --oneline  ${hash}..${branch} -- ${dep_api_dir})

    popd > /dev/null

    echo "${newer_commits}"
}

get_last_replace_for_mod_line() {
    local go_mod_file=$1
    local go_mod_line=$2

    local dep=$(echo ${go_mod_line} | cut -d' ' -f1)

    # if no replace for the dep then return original mod line
    result=$go_mod_line

    while read replace_line;
    do
        result=$(echo "$replace_line" | cut -d '>' -f2)
    done < <(grep $dep ${go_mod_file} | grep replace)

    # trim leading whitespace
    echo "${result##*( )}"
}

WORK_DIR=$(mktemp -d)

function cleanup {
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

branch=${BRANCH:-'main'}
go_mod_file=${MOD_FILE:-'go.mod'}

own_mod=$(head -n 1 $go_mod_file | cut -d ' ' -f 2)

errors="0"

while read go_mod_line;
do
    go_mod_line=$(get_last_replace_for_mod_line "$go_mod_file" "$go_mod_line")
    newer=$(newer_significant_commits "${go_mod_line}" "${branch}")
    if [ ! -z "${newer}" ];
    then
        errors=$((errors + 1))
        echo "New since ${go_mod_line}:"
        echo "$newer" | sed -e 's|^|* |'
        echo
    fi
done < <(grep openstack-k8s-operators ${go_mod_file} | grep -v $own_mod | grep -v replace | grep -v lib-common)

exit $errors

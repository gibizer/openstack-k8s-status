#!/bin/env python3
import subprocess
import sys
import os
import logging

logging.basicConfig()
LOG = logging.getLogger()


def remove_suffixes(s, suffixes):
    stripped = s
    for suffix in suffixes:
        stripped = stripped.removesuffix(suffix)

    return stripped

def build_dep_graph(repos):
    graph = set() # of pairs as dependency from -> to

    for dir in os.listdir(repos):
        f = os.path.join(repos, dir)
        if not os.path.isdir(f):
            continue
        if "lib-common" in f:
            continue

        build_dep_graph_for_repo(f, graph)

    return graph


def build_dep_graph_for_repo(go_mod_path, graph):

    cmd = f"cd {go_mod_path} && go mod graph"
    for line in subprocess.check_output(cmd, shell=True).split(b'\n'):
        line = line.decode('utf8')
        if not line:
            continue

        _from, to = line.split()
        from_mod  = _from.split("@")[0]
        to_mod = to.split("@")[0]

        # filter to our project only
        if "openstack-k8s-operators" not in from_mod:
            continue
        if "openstack-k8s-operators" not in to_mod:
            continue

        # remove module suffix as we interested in repo dependencies
        # and these modules are in the same repo
        suffixes = [
            "/api", "/apis",
            "/modules/ansible", "/modules/certmanager", "/modules/common",
            "/modules/openstack", "/modules/storage", "/modules/test",
            ]
        from_mod = remove_suffixes(from_mod, suffixes)
        to_mod = remove_suffixes(to_mod, suffixes)

        # ignore deps within repo
        if from_mod == to_mod:
            continue

        if "lib-common" in from_mod:
            LOG.warn(
                f"lib common dep loop in repo {go_mod_path} " +
                f"with dep direction {line}")
            continue

        graph.add((from_mod, to_mod))

    return graph

def get_all_deps(mod, graph):
    deps = set()
    for f, t in graph:
        if mod == f:
            deps.add(t)
    return deps

def bump_order(graph):
    order = []

    satisfied_deps = {"github.com/openstack-k8s-operators/lib-common"}
    order = [{"github.com/openstack-k8s-operators/lib-common"}]

    to_satisfy = {f for f, _ in graph}
    to_satisfy -= satisfied_deps

    deps = {mod: get_all_deps(mod, graph) for mod in to_satisfy}

    while to_satisfy:
        satisfied_this_round = set()
        for mod in to_satisfy:
            result = [dep in satisfied_deps for dep in deps[mod]]
            if all(result):
                satisfied_this_round.add(mod)

        satisfied_deps.update(satisfied_this_round)
        to_satisfy -= satisfied_this_round
        order.append(satisfied_this_round)

    return order

def main():
    g = build_dep_graph("./repos")
    order = bump_order(g)

    for i, batch in enumerate(order):
        print(f"## Batch {i}")
        for dep in sorted(batch):
            print(f"* [{dep}](http://{dep})")


if __name__ == "__main__":
    main()

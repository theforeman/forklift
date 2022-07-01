#!/usr/bin/env bash
# this is a very crude hack and can be removed once we have no more python2 systems
# that need to run this code
"exec" "$(command -v python3 || command -v python)" "$0" "$@"
# Adapted from Mark Mandel's implementation
# https://github.com/ansible/ansible/blob/devel/plugins/inventory/vagrant.py
import argparse
import json
import os
import subprocess
import sys

try:
    from StringIO import StringIO  # pyright: reportMissingImports=false
except ImportError:
    from io import StringIO  # pyright: reportMissingImports=false

from collections import defaultdict


try:
    DEVNULL = subprocess.DEVNULL
except AttributeError:
    DEVNULL = open(os.devnull, 'w')


def parse_args():
    parser = argparse.ArgumentParser(description="Vagrant inventory script")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--list', action='store_true')
    group.add_argument('--host')
    return parser.parse_args()


def get_running_hosts():
    try:
        subprocess.check_call(["which", "vagrant"], stdout=DEVNULL)
    except subprocess.CalledProcessError:
        return

    cmd = "vagrant status --machine-readable"
    status = subprocess.check_output(cmd.split(), universal_newlines=True).rstrip()

    for line in status.split('\n'):
        if len(line.split(',')) == 4:
            (_, host, key, value) = line.split(',')
        else:
            (_, host, key, value, _) = line.split(',')

        if key == 'state' and value in ('active', 'running'):
            yield host


def list_running_hosts():
    hosts = list(get_running_hosts())
    variables = dict(get_configs(hosts))

    return {
        "_meta": {
            "hostvars": variables,
        },
        "all": {
            "hosts": hosts,
        },
    }


def get_ssh_configs(hosts):
    cmd = ['vagrant', 'ssh-config'] + hosts
    try:
        output = subprocess.check_output(cmd, universal_newlines=True, stderr=DEVNULL)
    except subprocess.CalledProcessError:
        return None

    config = defaultdict(dict)
    host = None

    for line in output.splitlines():
        line = line.strip()
        if not line:
            continue
        key, value = line.split(None, 1)
        if key == 'Host':
            host = value
        elif host:
            config[host][key.lower()] = value

    return config


def get_host_ssh_config(config, host):
    ssh = config.get(host)
    return {'ansible_host': ssh['hostname'],
            'ansible_port': ssh['port'],
            'ansible_user': ssh['user'],
            'ansible_ssh_private_key_file': ssh['identityfile']}


def get_variables(hosts):
    cmd = [os.path.join(os.path.dirname(os.path.dirname(__file__)), 'bin', 'ansible-vars')] + hosts
    try:
        output = subprocess.check_output(cmd, universal_newlines=True, stderr=DEVNULL)
    except subprocess.CalledProcessError:
        return {}

    return json.loads(output)


def get_configs(hosts):
    if not hosts:
        return

    ssh_configs = get_ssh_configs(hosts)
    variables = get_variables(hosts)

    for host in hosts:
        details = {}
        if host in variables:
            details.update(variables[host])
        if ssh_configs:
            details.update(get_host_ssh_config(ssh_configs, host))
        yield host, details


def main():
    args = parse_args()
    if args.list:
        hosts = list_running_hosts()
        json.dump(hosts, sys.stdout)
    elif args.host:
        details = dict(get_configs([args.host]))
        json.dump(details[args.host], sys.stdout)


if __name__ == '__main__':
    main()

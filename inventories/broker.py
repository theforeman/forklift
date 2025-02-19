#!/usr/bin/env python

import argparse
import json
import yaml
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
    parser = argparse.ArgumentParser(description="Broker inventory script")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--list', action='store_true')
    group.add_argument('--host')
    return parser.parse_args()


def get_running_hosts():
    try:
        subprocess.check_call(["which", "broker"], stdout=DEVNULL)
    except subprocess.CalledProcessError:
        return

    cmd = "broker inventory --details"
    output = subprocess.check_output(cmd.split(), universal_newlines=True).rstrip()

    hosts = yaml.safe_load(output)
    return hosts.values()


def list_running_hosts():
    hosts = get_running_hosts()
    variables = dict(get_configs(hosts))

    return {
        "_meta": {
            "hostvars": variables,
        },
        "all": {
            "hosts": [host['hostname'] for host in hosts],
        },
    }


def get_configs(hosts):
    if not hosts:
        return

    for host in hosts:
        details = {
            'ansible_host': host['ip'],
            'ansible_port': '22',
            'ansible_user': 'root'
        }
        yield host['hostname'], details


def main():
    args = parse_args()
    hosts = list_running_hosts()

    if args.list:
        json.dump(hosts, sys.stdout)
    elif args.host:
        details = hosts['_meta']['hostvars']
        json.dump(details[args.host], sys.stdout)


if __name__ == '__main__':
    main()

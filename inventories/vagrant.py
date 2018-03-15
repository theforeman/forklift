#!/usr/bin/env python2
# Adapted from Mark Mandel's implementation
# https://github.com/ansible/ansible/blob/devel/plugins/inventory/vagrant.py
import argparse
import json
import paramiko
import subprocess
import sys
import os

def parse_args():
    parser = argparse.ArgumentParser(description="Vagrant inventory script")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--list', action='store_true')
    group.add_argument('--host')
    return parser.parse_args()


def list_running_hosts():
    hosts = {}

    with open(os.devnull, 'w') as FNULL:
        try:
            subprocess.check_call(["which","vagrant"], stdout=FNULL)
        except subprocess.CalledProcessError as e:
            return hosts

    cmd = "vagrant status --machine-readable"
    status = subprocess.check_output(cmd.split()).rstrip()
    for line in status.split('\n'):
        if len(line.split(',')) == 4:
            (_, host, key, value) = line.split(',')
        else:
            (_, host, key, value, provider) = line.split(',')

        if key == 'state' and value in ('active', 'running'):
            hosts[host] = get_host_details(host)
    return hosts


def get_host_details(host):
    cmd = "vagrant ssh-config {}".format(host)
    with open(os.devnull, 'w') as FNULL:
        try:
            subprocess.check_call(cmd.split(), stdout=FNULL, stderr=FNULL)
        except subprocess.CalledProcessError as e:
            return {}

    p = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
    config = paramiko.SSHConfig()
    config.parse(p.stdout)
    c = config.lookup(host)
    return {'ansible_host': c['hostname'],
            'ansible_port': c['port'],
            'ansible_user': c['user'],
            'ansible_ssh_private_key_file': c['identityfile'][0]}


def main():
    args = parse_args()
    if args.list:
        hosts = list_running_hosts()
        json.dump(hosts, sys.stdout)
    elif args.host:
        details = get_host_details(args.host)
        json.dump(details, sys.stdout)

if __name__ == '__main__':
    main()

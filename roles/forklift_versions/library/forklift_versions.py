#!/usr/bin/python

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r"""
module: forklift_versions
author: Evgeni Golov <evgeni@redhat.com>
short_description: fetch versions from Forklift's versions.yaml
description:
    - This returns the component versions of a Forklift scenario
options:
  file:
    description: path to versions.yaml
    required: True
  scenario:
    description: scenario to look up
    required: True
    choices:
      - foreman
      - katello
      - luna
      - plugins
  scenario_version:
    description: scenario version to look up
    required: True
  scenario_os:
    description: scenario OS to look up
    required: True
  upgrade:
    description: look up upgrade path instead of individual component versions
    type: bool
    default: False
  upgrade_step:
    description: how many versions to upgrade at once
    type: int
    default: 1
"""

import yaml
from ansible.module_utils.basic import AnsibleModule


TOTAL_UPGRADE_VERSIONS = 3
SCENARIO_MAP = {'plugins': 'foreman', 'luna': 'katello'}


def version_sort_key(version):
    try:
        return [int(u) for u in version.split('.')]
    except ValueError:
        return [9999, 9999, 9999]


def main():
    module = AnsibleModule(
        argument_spec=dict(
            file=dict(type='path', required=True),
            scenario=dict(type='str', required=True, choices=['foreman', 'katello', 'luna', 'plugins']),
            scenario_version=dict(type='str', required=True),
            scenario_os=dict(type='str', required=True),
            upgrade=dict(type='bool', default=False),
            upgrade_step=dict(type='int', default=1)
        ),
        supports_check_mode=True
    )

    ret = {}

    scenario = SCENARIO_MAP.get(module.params['scenario'], module.params['scenario'])
    scenario_os = module.params['scenario_os']
    scenario_version = module.params['scenario_version']

    with open(module.params['file'], 'r') as versions_file:
        versions = yaml.safe_load(versions_file)

    if not module.params['upgrade']:
        for version in versions['installers']:
            if not scenario_os in version['boxes']:
                continue
            if version[scenario] == scenario_version:
                forklift_vars = {
                        'foreman_repositories_version': version['foreman'],
                        'foreman_client_repositories_version': version['foreman'],
                        'katello_repositories_version': version['katello'],
                        'foreman_puppet_repositories_version': version['puppet'],
                        'pulpcore_repositories_version': version['pulpcore'],
                        }
                ret = forklift_vars
                break
    else:
        possible_versions = set()
        for version in reversed(versions['installers']):
            if not scenario_os in version['boxes']:
                continue
            # this is a hack, to be removed once all Katello versions support EL8 in the same manner Foreman does
            # aka: when 4.4 is released
            if scenario == 'katello' and (scenario_os.startswith('centos8') or scenario_os.startswith('almalinux8')) and version_sort_key(version[scenario]) < version_sort_key('4.0'):
                continue
            if version_sort_key(version[scenario]) <= version_sort_key(scenario_version):
                possible_versions.add(version[scenario])
        possible_versions = list(sorted(possible_versions, key=version_sort_key, reverse=True))
        upgrade_versions = possible_versions[::module.params['upgrade_step']][:TOTAL_UPGRADE_VERSIONS]
        upgrade_versions = sorted(upgrade_versions, key=version_sort_key)
        while len(upgrade_versions) < TOTAL_UPGRADE_VERSIONS:
            upgrade_versions.insert(0, upgrade_versions[0])
        ret = upgrade_versions

    module.exit_json(changed=False, versions=ret)

if __name__ == '__main__':
    main()

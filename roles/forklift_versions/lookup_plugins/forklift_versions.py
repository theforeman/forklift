# python 3 headers, required if submitting to Ansible
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = r"""
lookup: forklift_versions
author: Evgeni Golov <evgeni@redhat.com>
version_added: "0.9"
short_description: fetch versions from Forklift's versions.yaml
description:
    - This lookup returns the component versions of a Forklift scenario
options:
  file:
    description: path to versions.yaml
    required: True
  scenario:
    description: scenario to look up
    required: True
  scenario_version:
    description: scenario version to look up
notes:
  - this lookup will match the foreman version for the foreman scenatio
  - this lookup will match the katello version for all other scenarios
"""
import yaml
from ansible.errors import AnsibleParserError, AnsibleLookupError
from ansible.plugins.lookup import LookupBase

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()


TOTAL_UPGRADE_VERSIONS = 3


def version_sort_key(version):
    try:
        return [int(u) for u in version.split('.')]
    except ValueError:
        return [9999, 9999, 9999]


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        ret = []

        for term in terms:
            display.debug("Forklift lookup term: %s" % term)

            lookup_params = dict(x.split('=', 1) for x in term.split())

            try:
                scenario = lookup_params['scenario']
                if scenario != 'foreman':
                    scenario = 'katello'
                scenario_version = lookup_params['scenario_version']
                versions_file_name = lookup_params['file']
                upgrade = lookup_params.get('upgrade', False)
            except KeyError:
                raise AnsibleParserError("missing required param for forklift_version")

            try:
                with open(versions_file_name, 'r') as versions_file:
                    versions = yaml.safe_load(versions_file)
            except Exception:
                raise AnsibleLookupError("couldn't read '%s'" % versions_file_name)

            if not upgrade:
                for version in versions['installers']:
                    if version[scenario] == scenario_version:
                        forklift_vars = {
                                'foreman_repositories_version': version['foreman'],
                                'foreman_client_repositories_version': version['foreman'],
                                'katello_repositories_version': version['katello'],
                                'katello_repositories_pulp_version': version['pulp'],
                                'pulp_repositories_version': version['pulp'],
                                'puppet_repositories_version': version['puppet'],
                                }
                        ret.append(forklift_vars)
                        break
            else:
                upgrade_versions = set()
                for version in reversed(versions['installers']):
                    if version[scenario] == scenario_version:
                        upgrade_versions.add(scenario_version)
                    elif 1 <= len(upgrade_versions) < TOTAL_UPGRADE_VERSIONS:
                        upgrade_versions.add(version[scenario])

                if len(upgrade_versions) == 0:
                    raise AnsibleLookupError("could not find %s/%s" % (scenario, scenario_version))

                upgrade_versions = sorted(upgrade_versions, key=version_sort_key)
                while len(upgrade_versions) < TOTAL_UPGRADE_VERSIONS:
                    upgrade_versions.insert(0, upgrade_versions[0])
                ret.append(upgrade_versions)

        return ret

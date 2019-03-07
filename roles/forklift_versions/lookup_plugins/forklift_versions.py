# python 3 headers, required if submitting to Ansible
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = """
      lookup: forklift_versions
        author: Evgeni Golov <evgeni@redhat.com>
        version_added: "0.9"
        short_description: fetch Foreman/Katello versions from Forklift's versions.yaml
        description:
            - This lookup returns the component versions of a Foreman/Katello scenario
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
from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.lookup import LookupBase

try:
    from __main__ import display
except ImportError:
    from ansible.utils.display import Display
    display = Display()


class LookupModule(LookupBase):

    def run(self, terms, variables=None, **kwargs):
        ret = []

        for term in terms:
            display.debug("Forklift lookup term: %s" % term)
            lookup_params = dict(x.split('=', 1) for x in term.split())
            scenario = lookup_params['scenario']
            scenario_version = lookup_params['scenario_version']

            # Find the file in the expected search path, using a class method
            # that implements the 'expected' search path for Ansible plugins.
            #lookupfile = self.find_file_in_search_path(variables, 'files', term)

            # Don't use print or your own logging, the display class
            # takes care of it in a unified way.
            #display.vvvv(u"File lookup using %s as file" % lookupfile)
            with open(lookup_params['file'], 'r') as versionsfile:
                versions = yaml.safe_load(versionsfile)
            for version in versions['installers']:
                if ((scenario == 'foreman' and version['foreman'] == scenario_version) or
                   (scenario != 'foreman' and version['katello'] == scenario_version)):
                    forklift_vars = {
                            'foreman_repositories_version': version['foreman'],
                            'foreman_client_repositories_version': version['foreman'],
                            'katello_repositories_version': version['katello'],
                            'katello_repositories_pulp_version': version['pulp'],
                            'pulp_repositories_version': version['pulp'],
                            'puppet_repositories_version': version['puppet'],
                            }
                    ret.append(forklift_vars)

        return ret

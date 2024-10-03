# Testing Environments

This section covers test infrastructure and environments that can be spun up using Forklift.

## Bats Testing

Included with Forklift is a small live test suite. The current tests are:

| Test                                       | Description                                               |
| ------------------------------------------ | --------------------------------------------------------- |
| fb-test-foreman.bats                       | Runs a few simple tests for Foreman                       |
| fb-katello-client.bats                     | Runs client-related Katello content tests                 |
| fb-katello-client-global-registration.bats | Runs tests for the Global Registration feature            |
| fb-katello-content.bats                    | Runs tests against content features                       |
| fb-katello-content-restore.bats            | Runs non-destructive content tests after a backup restore |
| fb-katello-proxy.bats                      | Runs tests against content proxy features                 |
| fb-test-katello-change-hostname.bats       | Runs tests for the katello-change-hostname script         |
| fb-test-foreman-ansible.bats               | Runs tests for Foreman Ansible plugin                     |
| fb-test-foreman-rex.bats                   | Runs tests for Foreman Remote Execution plugin            |
| fb-test-foreman-templates.bats             | Runs tests for Foreman Templates plugin                   |
| fb-test-puppet.bats                        | Runs tests for Foreman Puppet plugin                      |
| fb-test-backup.bats                        | Runs tests for Foreman Maintain Backup feature            |
| fb-proxy-dns.bats                          | Runs DNS related proxy tests                              |
| fb-verify-packages.bats                    | Ensures no wrong package sets are installed               |
| fb-verify-selinux.bats                     | Ensures no SELinux errors happen                          |
| fb-virt-whom.bats                          | Run virt-whom candlepin tests                             |
| fb-destroy-organization.bats               | Cleans up after the content tests                         |

### To run the same setup run by CI system

```sh
cp boxes.yaml.example boxes.yaml
vagrant up centos9-katello-bats-ci
```

If you are making changes to bats tests and want to test your updates, edit `centos9-katello-bats-ci` to include:

```yaml
ansible:
  # ....
  variables:
    bats_forklift_dir: /vagrant
    bats_update_forklift: "no"
```

Or if you want to run bats from a different repository or branch, edit `centos9-katello-bats-ci` to include:

```yaml
ansible:
  # ...
  variables:
    bats_forklift_repo: https://github.com/<YOUR_NAME>/forklift.git
    bats_forklift_version: your-branch
```

### To run Bats on an existing VM for development

1. Install `bats`: `dnf install bats` or `apt install bats`
2. Make sure your Foreman server is running
3. If your tests use Hammer, make sure you have a working `hammer` command
4. `cd` to your `forklift` directory
5. Run bats by specifying the test filename(s):

```sh
bats bats/fb-katello-content.bats
```

NOTE: Bats tests are not idempotent, so you may have to do some cleanup or skip some tests when running bats multiple times.

## Pipeline Testing

Under `pipelines` are a series of playbooks designed around testing scenarios for various version of the Foreman and Katello stack. To run one:

```sh
ansible-playbook pipelines/<pipeline>.yml -e forklift_state=up -e <vars required by pipeline>
```

When you are finished with the test, you can tear down the associated infrastructure:

```sh
ansible-playbook pipelines/<pipeline>.yml -e forklift_state=destroy -e <vars required by pipeline>
```

### Existing Pipelines

* `install_pipeline` - Installs a Server and a Proxy VMs and runs the `foreman_testing` role to verify the setup.  
  Expects the `pipeline_os` variable to be set to a known OS (currently: centos9-stream, debian10).  
  Expects the `pipeline_type` variable to be set to a known type (currently: foreman, katello, luna).  
  Expects the `pipeline_version` variable to be set to a known version (currently: 3.8, 3.9, 3.10, 3.11, nightly).
* `upgrade_pipeline` - Installs a VM, upgrades it twice and runs the `foreman_testing` role to verify the final upgrade.  
  Expects the `pipeline_os` variable to be set to a known OS (currently: centos9-stream, debian10).  
  Expects the `pipeline_type` variable to be set to a known type (currently: foreman, katello, luna).  
  Expects the `pipeline_version` variable to be set to a known version (currently: 3.8, 3.9, 3.10, 3.11, nightly).

#### Examples

```sh
ansible-playbook pipelines/install_pipeline.yml -e forklift_state=up -e pipeline_os=debian10 -e pipeline_type=foreman -e pipeline_version=nightly
ansible-playbook pipelines/upgrade_pipeline.yml -e forklift_state=up -e pipeline_os=centos9-stream -e pipeline_type=katello -e pipeline_version=3.10
```

### Creating Pipelines

If you wish to add a new version of an existing pipeline (e.g. a new Katello release), you only have to add the corresponding vars files to `pipelines/vars/`.

For Katello 3.11, you'd be adding the following two files:

`pipelines/vars/katello_3.11.yml`:

```yaml
forklift_name: pipeline-katello-3.11
forklift_boxes:
  pipeline-katello-3.11-centos9:
    box: centos9-stream
    memory: 8192
  pipeline-proxy-3.11-centos9:
    box: centos9-stream
    memory: 3072
katello_repositories_version: "3.11"
foreman_repositories_version: "1.21"
foreman_client_repositories_version: "{{ foreman_repositories_version }}"
```

`pipelines/vars/katello_upgrade_3.11.yml`:

```yaml
katello_version_start: "3.9"
katello_version_intermediate: "3.10"
katello_version_final: "{{ katello_version }}"
```

## Running Robottelo Tests

Robottelo is a test suite for exercising Foreman and Katello. Forklift provides a role for Robottelo to set up and run tests against your machine. Configuration options of interest are `robottelo_test_endpoints` where you can pass a list of endpoints (api, cli or ui), and `robottelo_test_type`, which is one of:

* tier1 to tier4 - base test sets, tier1 tests can resemble unit testing, higher tiers require more extensive setup
* destructive - tests that restart or rename the server
* upgrade - a selection of tests from tiers used in post-upgrade testing, should exercise the core functionality in less time consuming way
* endtoend - testing the essential user scenario, less time-consuming than the upgrade set

* [Robottelo repository](https://github.com/SatelliteQE/robottelo)
* [Robottelo documentation](https://robottelo.readthedocs.io/en/latest/)

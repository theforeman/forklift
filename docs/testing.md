# Testing Environments

This section covers test infrastructure and environments that can be spun up using Forklift.

 * [Bats Testing](#bats-testing)
 * [Running Robottelo Tests](#running-robottelo-tests)

# Bats Testing

Included with forklift is a small live test suite.  The current tests are:

  * fb-test-foreman.bats - Runs a few simple tests for Foreman
  * fb-test-katello.bats - Runs a few simple tests for Katello
  * fb-content-katello.bats - Runs tests against content features
  * fb-proxy.bats - Runs tests against content proxy features
  * fb-destroy-organization.bats - Cleans up after the content tests
  * fb-finish.bats - Collects logs pertinent to the bats run

### To run the same setup run by CI system

```
cp boxes.yaml.example boxes.yaml
vagrant up centos7-katello-bats-ci
```

If you are making changes to bats tests and want to test your updates, edit `centos7-katello-bats-ci` to include:

    ansible:
      ....
      variables:
        bats_forklift_dir: /vagrant
        bats_update_forklift: "no"

Or if you want to run bats from a different repository or branch, edit `centos7-katello-bats-ci` to include:

    ansible:
      ....
      variables:
        bats_forklift_repo: https://github.com/<YOUR_NAME>/forklift.git
        bats_forklift_version: your-branch

### To run Bats on an existing VM for development

1. Install `bats`: `yum install bats` or `apt install bats`
2. Make sure your Foreman server is running
3. If your tests use Hammer, make sure you have a working `hammer` command
4. `cd` to your `forklift` directory
5. Run bats by specifying the test filename(s):

```
bats bats/fb-katello-content.bats
```

_Note_: Bats tests are not idempotent, so you may have to do some cleanup or skip some tests when running bats multiple times.


# Pipeline Testing

Under `pipelines` are a series of playbooks designed around testing scenarios for various version of the Foreman and Katello stack. To run one:

    ansible-playbook pipelines/<pipeline>.yml -e forklift_state=up -e <vars required by pipeline>

When you are finished with the test, you can tear down the associated infrastructure:

    ansible-playbook pipelines/<pipeline>.yml -e forklift_state=destroy -e <vars required by pipeline>

## Existing Pipelines

* `install_pipeline` - Installs a Server and a Proxy VMs and runs the `foreman_testing` role to verify the setup.
  Expects the `pipeline_os` variable to be set to a known OS (currently: centos7, debian10)
  Expects the `pipeline_type` variable to be set to a known type (currently: foreman, katello, luna)
  Expects the `pipeline_version` variable to be set to a known version (currently: 3.8, 3.9, 3.10, 3.11, nightly)
  Accepts the `pipeline_proxy_delay` variable to install the Proxy with an older version than the Server (default: `0`)
* `upgrade_pipeline` - Installs a VM, upgrades it twice and runs the `foreman_testing` role to verify the final upgrade.
  Expects the `pipeline_os` variable to be set to a known OS (currently: centos7, debian10)
  Expects the `pipeline_type` variable to be set to a known type (currently: foreman, katello, luna)
  Expects the `pipeline_version` variable to be set to a known version (currently: 3.8, 3.9, 3.10, 3.11, nightly).

#### Examples

    ansible-playbook pipelines/install_pipeline.yml -e forklift_state=up -e pipeline_os=debian10 -e pipeline_type=foreman -e pipeline_version=nightly
    ansible-playbook pipelines/install_pipeline.yml -e forklift_state=up -e pipeline_os=centos7 -e pipeline_type=katello -e pipeline_version=nightly -e pipeline_proxy_delay=1
    ansible-playbook pipelines/upgrade_pipeline.yml -e forklift_state=up -e pipeline_os=centos7 -e pipeline_type=katello -e pipeline_version=3.10

# Running Robottelo Tests

Robottelo is a test suite for exercising Foreman and Katello. Forklift provides a role for Robottelo to set up and run tests against your machine. Configuration options of interest are `robottelo_test_endpoints` where you can pass a list of endpoints (api, cli or ui), and `robottelo_test_type`, which is one of:

- tier1 to tier4 - base test sets, tier1 tests can resemble unit testing, higher tiers require more extensive setup
- destructive - tests that restart or rename the server
- upgrade - a selection of tests from tiers used in post-upgrade testing, should exercise the core functionality in less time consuming way
- endtoend - testing the essential user scenario, less time-consuming than the upgrade set

 * [Robottelo repository](https://github.com/SatelliteQE/robottelo)
 * [Robottelo documentation](https://robottelo.readthedocs.io/en/latest/)

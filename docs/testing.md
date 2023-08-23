# Testing Environments

This section covers test infrastructure and environments that can be spun up using Forklift.

## Bats Testing

Included with forklift is a small live test suite.  The current tests are:

  * fb-test-foreman.bats - Runs a few simple tests for Foreman
  * fb-katello-client.bats - Runs client-related Katello content tests
  * fb-katello-client-global-registration.bats - Runs tests for the Global Registration feature
  * fb-katello-content.bats  - Runs tests against content features
  * fb-katello-content-restore.bats - Runs non-destructive content tests after a backup restore
  * fb-katello-proxy.bats - Runs tests against content proxy features
  * fb-test-katello-change-hostname.bats - Runs tests for the katello-change-hostname script
  * fb-test-foreman-ansible.bats - Runs tests for Foreman Ansible plugin
  * fb-test-foreman-rex.bats - Runs tests for Foreman Remote Execution plugin
  * fb-test-foreman-templates.bats - Runs tests for Foreman Templates plugin
  * fb-test-puppet.bats - Runs tests for Foreman Puppet plugin
  * fb-test-backup.bats - Runs tests for Foreman Maintain Backup feature
  * fb-proxy-dns.bats - Runs DNS related proxy tests
  * fb-verify-packages.bats - Ensures no wrong package sets are installed
  * fb-verify-selinux.bats - Ensures no SELinux errors happen
  * fb-virt-whom.bats - Run virt-whom candlepin tests
  * fb-destroy-organization.bats - Cleans up after the content tests

### To run the same setup run by CI system

```
cp boxes.yaml.example boxes.yaml
vagrant up centos7-katello-bats-ci
```

If you are making changes to bats tests and want to test your updates, edit `centos7-katello-bats-ci` to include:

```yaml
ansible:
  # ....
  variables:
    bats_forklift_dir: /vagrant
    bats_update_forklift: "no"
```

Or if you want to run bats from a different repository or branch, edit `centos7-katello-bats-ci` to include:

```yaml
ansible:
  # ...
  variables:
    bats_forklift_repo: https://github.com/<YOUR_NAME>/forklift.git
    bats_forklift_version: your-branch
```

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


## Pipeline Testing

Under `pipelines` are a series of playbooks designed around testing scenarios for various version of the Foreman and Katello stack.
Use `./bin/forklift --help` to find out which ones and their aguments.

```console
$ ./bin/forklift --help
usage: forklift [-h] action ...

positional arguments:
  action      which action to execute
    install   Run an install pipeline
    upgrade   Run an upgrade pipeline

optional arguments:
  -h, --help  show this help message and exit
```

Individual pipelines also have help texts:
```console
$ ./bin/forklift install --help
usage: forklift install [-h] [-v] [-e EXTRA_VARS] [--state FORKLIFT_STATE] [--os PIPELINE_OS] [--type PIPELINE_TYPE] [--version PIPELINE_VERSION]

Run an install pipeline

options:
  -h, --help            show this help message and exit
  -v, --verbose         verbose output
  --state FORKLIFT_STATE
                        Forklift state to ensure
  --os PIPELINE_OS      Operating system to install, like centos8-stream, debian11 or ubuntu2004. Valid options depend on the pipeline
  --type PIPELINE_TYPE  Type of pipeline, like foreman, katello or luna
  --version PIPELINE_VERSION
                        Version to install, like nightly, 3.7 or 4.9

advanced arguments:
  -e EXTRA_VARS, --extra-vars EXTRA_VARS
                        set additional variables as key=value or YAML/JSON, if filename prepend with @
```

Pipelines typically have a state which defaults to `up`. Other valid values are `rebuild` and `destroy`. The latter one is useful to clean up which pipelines don't do by themselves.

For example to run a Foreman Nightly installation pipeline on Debian Bullseye:

```console
$ ./bin/forklift install --os debian11 --type foreman --version nightly
... lots of output
```

When you're done, you can delete the boxes by adding `--state destroy`:

```console
$ ./bin/forklift install --os debian11 --type foreman --version nightly --state destroy
```

Similarly a Katello Nightly upgrade pipeline on CentOS 8 Stream:

```console
$ ./bin/forklift upgrade --os centos8-stream --type katello --version nightly
```

## Running Robottelo Tests

Robottelo is a test suite for exercising Foreman and Katello. Forklift provides a role for Robottelo to set up and run tests against your machine. Configuration options of interest are `robottelo_test_endpoints` where you can pass a list of endpoints (api, cli or ui), and `robottelo_test_type`, which is one of:

- tier1 to tier4 - base test sets, tier1 tests can resemble unit testing, higher tiers require more extensive setup
- destructive - tests that restart or rename the server
- upgrade - a selection of tests from tiers used in post-upgrade testing, should exercise the core functionality in less time consuming way
- endtoend - testing the essential user scenario, less time-consuming than the upgrade set

 * [Robottelo repository](https://github.com/SatelliteQE/robottelo)
 * [Robottelo documentation](https://robottelo.readthedocs.io/en/latest/)

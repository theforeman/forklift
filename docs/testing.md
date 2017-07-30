# Testing Environments

This section covers test infrastructure and environments that can be spun up using Forklift.

 * [Bats Testing](#bats-testing)
 * [Client Testing with Docker](#client-testing-with-docker)

## Bats Testing

Included with forklift is a small live test suite.  The current tests are:

  * fb-test-foreman.bats - Runs a few simple tests for Foreman
  * fb-test-katello.bats - Runs a few simple tests for Katello
  * fb-content-katello.bats - Runs tests against content features
  * fb-proxy.bats - Runs tests against content proxy features
  * fb-destroy-organization.bats - Cleans up after the content tests
  * fb-finish-katello.bats - Collects logs pertinent to the bats run

To execute the bats framework:

 * Using vagrant (after configuring vagrant according to this document):

    vagrant up centos7-pipeline-bats

To run the same setup run by CI system:

    cp boxes.yaml.example boxes.yaml
    vagrant up centos7-bats-ci

If you are making changes to bats tests and want to test your updates, edit `centos7-bats-ci` to include:

    ansible:
      ....
      variables:
        bats_forklift_dir: /vagrant
        bats_update_forklift: "no" 

Or if you want to run bats from a different repository or branch, edit `centos7-bats-ci` to include:

    ansible:
      ....
      variables:
        bats_forklift_repo: https://github.com/<YOUR_NAME>/forklift.git
        bats_forklift_version: your-branch

## Pipeline Testing

Under `pipelines` are a series of playbooks designed around testing scenarios for various version of the Foreman and Katello stack. To run one:

    ansible-playbook pipelines/pipeline_katello_nightly.yml -e "forklift_state=up"

When you are finished with the test, you can tear down the associated infrastructure:

    ansible-playbook pipelines/pipeline_katello_nightly.yml -e "forklift_state=destroy"

## Client Testing With Docker

The docker/clients directory contains setup and configuration to register clients via subscription-manager using an activation key and start katello-agent. Before using the client containers, Docker and docker-compose need to be installed and setup. On a Fedora based system (Fedora 23 or greater):

```
sudo yum install docker docker-compose
sudo service docker start
sudo chkconfig docker on
sudo usermod -aG docker your_username
```

For other platforms see the official instructions at:

 * [docker](https://docs.docker.com/installation/)
 * [docker-compose](https://docs.docker.com/compose/install/)

In order to use the client containers you will also need the following:

 * Foreman/Katello server IP address
 * Foreman/Katello server hostname
 * Foreman Organization
 * Activation Key
 * Katello version you have deployed (e.g. nightly, 2.2)

Begin by changing into the docker/clients directory and copying the `docker-compose.yml.example` file to `docker-compose.yml` and filling in the necessary information gathered above. At this point, you can now spin-up one or more clients of varying types. For example, if you wanted to spin up a centos6 based client:

```
docker-compose up el6
```

If you want to spin up more than one client, let's say 10 for this example, the docker-compose scale command can be used:

```
docker-compose scale el6=10
```

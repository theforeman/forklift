# Testing Environments

This section covers test infrastructure and environments that can be spun up using Forklift.

 * [Bats Testing](#bats-testing)
 * [Client Testing with Docker](#client-testing-with-docker)

## Bats Testing

Included with forklift is a small live test suite.  The current tests are:

  * fb-install-katello.bats - Installs katello and runs a few simple tests

To execute the bats framework:

 * Using vagrant (after configuring vagrant according to this document):
  1.  vagrant up centos6-bats
  2.  vagrant ssh centos6-bats -c 'sudo fb-install-katello.bats'

 * On a fresh system you've manually installed:
  1.  ./bats/bootstrap.sh
  2.  katello-bats

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

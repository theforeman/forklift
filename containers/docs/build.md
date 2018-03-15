# Build

The build phase is handled by the `ansible-container` project using Ansible roles to build out each container in preparation to push to a registry. This document will walk through how to build the containers.

  1. [Install ansible](#install-ansible)
  2. [Setup Docker](#setup-docker)
  3. [Install ansible-container](#install-ansible-container)
  4. [Build Containers](#build-containers)

This installation guide assumes that you are working from the `forklift/containers` directory for all actions.


## Setup Dependencies

### Install Ansible

Parts of the setup have been automated using Ansible to ensure consistency and speed up getting to the deployment aspect. Please ensure you have the latest version of Ansible installed:

Using yum:

    sudo yum install ansible

Using pip:

    sudo pip install ansible

### Setup Docker

In order to build the containers, a running docker daemo needs to be present.

    ansible-playbook tools/install-docker.yml

### Install ansible-container

This project is currently using the bleeding edge version of `ansible-container` and will be installed from source. To simplify install, an Ansible playbook has been provided to do the installation:

    ansible-playbook tools/install-ansible-container.yml


## Build Containers

Now build the containers (and grab a coffee):

    ansible-playbook tools/build.yml

To build an individual (or multiple individual) services pass the name(s) space separated:

    ansible-playbook tools/build.yml -e services='foreman dynflow'

To build just Foreman:

    ansible-playbook tools/build-foreman.yml

To build just Pulp:

    ansible-playbook tools/build-pulp.yml

To build just Candlepin:

    ansible-playbook tools/build-candlepin.yml

This sort of smaller incremental building is good for small changes or rolling out a single service update for quicker development cycles.

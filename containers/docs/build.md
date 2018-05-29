# Build

This document will walk through how to build the containers.

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

In order to build the containers, a running docker daemon needs to be present. Follow the official Docker [installation](https://docs.docker.com/install/) guide or use the following Ansible playbook:

    ansible-playbook tools/install-docker.yml


## Build Containers

Now build all the container images (and grab a coffee):

    ansible-playbook tools/build-all.yml

To build a single container image:

    ansible-playbook tools/build.yml -e image=foreman

To build just the Foreman stack:

    ansible-playbook tools/build-foreman.yml

To build just the Pulp stack:

    ansible-playbook tools/build-pulp.yml

To build just the Candlepin stack:

    ansible-playbook tools/build-candlepin.yml

This sort of smaller incremental building is good for small changes or rolling out a single service update for quicker development cycles.

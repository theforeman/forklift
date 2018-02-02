## Setup

This setup is done in two phases: build and deployment. The build phase is handled by the `ansible-container` project using Ansible roles to build out each container in preparation to push to Openshift. The deployment phase can either be done locally or to a local or remote Openshift cluster. This README will walk through how to build and run on a local Openshift:

  1. [Install ansible](#install-ansible)
  2. [Install and Configure Docker](#setup-docker)
  3. [Install ansible-container](#install-ansible-container)
  4. [Build Containers](#build-containers)
  5. [Run Containers Locally](#run-containers-locally)
  6. [Setup and Install Local OpenShift](#setup-and-install-openshift)
  7. [Deploy Containers to OpenShift](#deploy-containers-to-openshift)

This installation guide assumes that you are working from the `forklift/containers` directory for all actions and that you have a fresh CentOS 7 VM running. Other OSes like Fedora can be used, but some aspects such as configuring docker may be different.

The rest of this guide will assume there is an Ansible inventory present configured to point at your CentOS 7 box.

### Install Ansible

Parts of the setup have been automated using Ansible to ensure consistency and speed up getting to the deployment aspect. Please ensure you have the latest version of Ansible installed:

Using yum:

    sudo yum install ansible

Using pip:

    sudo pip install ansible

At this point, if you want to skip ahead to the all in one at the bottom you can. However, if this is your first time we recommend running through each step individually to learn what each does and how to customize.

### Setup Docker

In order to build the containers, run them locally or use OpenShift, Docker needs to be installed and configured with an insecure registry.

    ansible-playbook tools/install-docker.yml -l centos7 -b -e "@vars/remote.yml"

### Install ansible-container

This project is currently using the bleeding edge version of `ansible-container` and will be installed from source. To simplify install, an Ansible playbook has been provided to do the installation:

    ansible-playbook tools/install-ansible-container.yml -l centos7 -b -e "@vars/remote.yml"

### Build Containers

Before the containers can be built the local copy of the container code needs to be synced to the CentOS box. This allows for making local changes in the future and having them tested through the various stages on the CentOS box:

    ansible-container tools/install-forklift.yml -l centos7 -b -e "@vars/remote.yml"

Now build the containers (and grab a coffee):

    ansible-playbook tools/build.yml -l centos7 -b -e "@vars/remote.yml"

To build an individual (or multiple individual) services pass the name(s) space separated:

   ansible-playbook tools/build.yml -l centos7 -b -e "@vars/remote.yml" -e services='foreman dynflow'

To build just Foreman:

  ansible-playbook tools/build-foreman.yml

To build just Pulp:

  ansible-playbook tools/build-pulp.yml

To build just Candlepin:

  ansible-playbook tools/build-candlepin.yml

This sort of smaller incremental building is good for small changes or rolling out a single service update for quicker development cycles.

### Setup and Install Openshift

This setup requires access to OpenShift 3.5 or later. The easiest way to run and play with this locally is to use the OpenShift Origin client tools 1.5+ and docker. This short guide will run through setting up a local test environment.

#### Setup OpenShift Client Tools

The ability to spin up an OpenShift cluster on docker was added to OpenShift Client Tools v1.3+. This has been abstracted into an Ansible playbook for your convenience.

    ansible-playbook tools/install-openshift-tools.yml -l centos7 -b -e "@vars/remote.yml"

You can change the version of the OpenShift Client Tools that are installed by editing the playbook or passing variables to the `ansible-playbook` command.

#### Setup OpenShift

Now that we have docker and the appropriate client tools setup we can spin up a docker based OpenShift cluster using the playbook to do this:

    ansible-playbook tools/configure-firewall.yml -l centos7 -b -e "@vars/remote.yml"
    ansible-playbook tools/cluster-up.yml -l centos7 -b -e "@vars/remote.yml"

### Deploy Containers to Openshift

Deploying the containers that were built involves pushing the containers to Openshift, generating a deployment role and then finally shipping them to Openshift. The first step in this is to generate a set of SSL certificates for the services to communicate with:

    ansible-playbook tools/generate-certificates.yml -l centos7 -b -e "@vars/remote.yml"

Now those certificates need to be turned into a Ansible secrets file:

    ansible-playbook tools/build-secrets.yml -l centos7 -b -e "@vars/remote.yml"

Now that we have generated our secrets file, the deployment role is ready to be generated:

    ansible-playbook tools/generate-deployment-role.yml -l centos7 -b -e "@vars/remote.yml"

Finally, the application stack is ready to be deployed to Openshift running on our VM:

    ansible-playbook tools/deploy.yml -l centos7 -b -e "@vars/remote.yml"

After the `foreman` role has entered the `Running` state, a basic application health check along with backend services can be performed. List the routes and locate the hostname the `foreman` route is deployed on, for example:

    oc get routes
    curl http://foreman-8080-openshift.10.13.129.60.xip.io/katello/api/v2/ping

### All In One

All of the steps above can be executed together through a single playbook:

    ansible-playbook tools/end-to-end.yml -l centos7 -b -e "@vars/remote.yml"

## Troubleshooting

### Authentication error when pushing images

While pushing images to Openshift you may receive `unauthorized: authentication required` this can sometimes result from previously stored login information that is now incorrect. This state can result from spinning up and down the cluster for testing. Either edit `~/.docker/config.yml` and remove the entry for the Openshift registry being pushed to or remove the file entirely.


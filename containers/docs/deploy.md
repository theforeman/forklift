# Deploy

The deployment phase can either be done to a local or remote Openshift cluster. This doc will go through how to run on a local Openshift running via containers.

  1. [Setup and Install Local OpenShift](#setup-and-install-openshift)
  2. [Deploy Containers to OpenShift](#deploy-containers-to-openshift)

This installation guide assumes that you are working from the `forklift/containers` directory for all actions. This guide will also use an Openshift spun via Docker containers running locally using the `oc cluster`.


## Setup Dependencies

### Install Ansible

Parts of the setup have been automated using Ansible to ensure consistency and speed up getting to the deployment aspect. Please ensure you have the latest version of Ansible installed:

Using yum:

    sudo yum install ansible

Using pip:

    sudo pip install ansible

### Setup Docker

In order to build the containers, run them locally or use OpenShift, Docker needs to be installed and configured with an insecure registry.

    ansible-playbook tools/install-docker.yml

### Setup and Install Openshift

This setup requires access to OpenShift 3.5 or later. The easiest way to run and play with this locally is to use the OpenShift Origin client tools 1.5+ and docker. This short guide will run through setting up a local test environment.

#### Setup OpenShift Client Tools

The ability to spin up an OpenShift cluster on docker was added to OpenShift Client Tools v1.3+. This has been abstracted into an Ansible playbook for your convenience.

    ansible-playbook tools/install-openshift-tools.yml

You can change the version of the OpenShift Client Tools that are installed by editing the playbook or passing variables to the `ansible-playbook` command.

#### Setup OpenShift

Now that we have docker and the appropriate client tools setup we can spin up a docker based OpenShift cluster using the playbook to do this:

    ansible-playbook tools/cluster-up.yml


## Deploy Containers to Openshift

Deploying the containers that were built involves pushing the containers to Openshift, generating a deployment role and then finally shipping them to Openshift. The first step in this is to generate a set of SSL certificates for the services to communicate with:

    ansible-playbook tools/generate-certificates.yml

Now those certificates need to be turned into a Ansible secrets file:

    ansible-playbook tools/build-secrets.yml

Finally, the application stack is ready to be deployed to Openshift running on our VM:

    ansible-playbook tools/deploy.yml -l centos7 -b -e "@vars/remote.yml"

After the `foreman` role has entered the `Running` state, a basic application health check along with backend services can be performed. List the routes and locate the hostname the `foreman` route is deployed on, for example:

    oc get routes
    curl http://foreman-8080-openshift.10.13.129.60.xip.io/katello/api/v2/ping

## Setup

This setup is done in two phases: build and deployment. The build phase is handled by the `ansible-container` project using Ansible roles to build out each container in preparation to push to Openshift. The deployment phase can either be done locally or to a local or remote Openshift cluster. This README will walk through how to build and run on Openshift:

  1. [Install ansible](#install-ansible)
  2. [Install and Configure Docker](#setup-docker)
  3. [Install ansible-container](#install-ansible-container)
  4. [Build Containers](#build-containers)
  5. [Run Containers Locally](#run-containers-locally)
  6. [Setup and Install Local OpenShift](#setup-and-install-openshift)
  7. [Deploy Containers to OpenShift](#deploy-containers-to-openshift)

This installation guide assumes that you are working from the `forklift/containers` directory for all actions.

### Install Ansible

Parts of the setup have been automated using Ansible to ensure consistency and speed up getting to the deployment aspect. Please ensure you have the latest version of Ansible installed:

Using yum:

    sudo yum install ansible

Using pip:

    sudo pip install ansible

### Setup Docker

In order to build the containers, run them locally or use OpenShift, Docker needs to be installed and configured properly. First, ensure that docker is installed:

    sudo yum install docker

Second, we need to allow for insecure registries to run. This can be enabled by editing `/etc/sysconfig/docker` and adding:

    INSECURE_REGISTRY='--insecure-registry 172.30.0.0/16'

Now restart the docker service:

    sudo systemctl restart docker

### Install ansible-container

This project is currently using the bleeding edge version of `ansible-container` and will be installed from source. To simplify install, an Ansible playbook has been provided to do the installation:

    ansible-playbook install-ansible-container.yml

### Build Containers

Now that `ansible-container` is installed, the containers can be built. This build takes a while and can cause the docker client to timeout. Thus, before building run:

    export DOCKER_CLIENT_TIMEOUT=600

Now build the containers (and grab a coffee):

    ./build.sh

To build an individual (or multiple individual) services pass the name(s) space separated:

   ./build.sh foreman-base foreman

This sort of smaller incremental building is good for small changes or rolling out a single service update for quicker development cycles.

### Run Containers Locally

Once the containers have been built locally into Docker, `ansible-container` can be used to run the entire stack locally:

    ansible-container run

This will expose the Foreman user interface at `http://0.0.0.0:8080`

### Setup and Install Openshift

This setup requires access to OpenShift 3.5 or later. The easiest way to run and play with this locally is to use the OpenShift Origin client tools 1.5+ and docker. This short guide will run through setting up a local test environment.

This setup guide was written using Fedora 23 but newer version of Fedora or Centos 7+ should work.

#### Setup OpenShift Client Tools

The ability to spin up an OpenShift cluster on docker was added to OpenShift Client Tools v1.3+. This has been abstracted into an Ansible playbook for your convenience.

    ansible-playbook install-openshift-tools.yml

You can change the version of the OpenShift Client Tools that are installed by editing the playbook or passing variables to the `ansible-playbook` command.

#### Setup OpenShift

Now that we have docker and the appropriate client tools setup we can spin up a docker based OpenShift cluster using the playbook to do this:

    ansible-playbook cluster-up.yml

Note that this will put all Openshift data in `/home/origin` by default as this assumes most users are developers whom have a majority of their data storage in their home directory. To configure this specify a new directory when running the playbook:

    ansible-playbook cluster-up.yml -e openshift_data_dir=/var/lib/origin

### Deploy Containers to Openshift

Deploying the containers that were built involves pushing the containers to Openshift, generating a deployment role and then finally shipping them to Openshift. The simplest method is to call the all in one playbook:

    ansible-playbook deploy.yml

Now, generate the deployment role that will use the images that were pushed:

    ansible-container --engine openshift deploy --push-to oc-cluster --username developer --password $(oc whoami -t)

The final step is deploy the role:

    ansible-playbook ansible-deployment/foreman.yml --tags start

At this point, all services will get created in Openshift and begin deploying. To check on the status of the deployment:

    oc get pods

After the `foreman` role has entered the `Running` state, a basic application health check along with backend services can be performed. List the routes and locate the hostname the `foreman` route is deployed on, for example:

    oc get routes
    curl http://foreman-8080-openshift.10.13.129.60.xip.io/katello/api/v2/ping

## Deployment Verification

As part of this deployment, there is an effort to verify the functionality of the deployment based upon automated testing. The current baseline for this is the `bats` testing that is performed on an installation on the Katello nightly pipeline. To perform this test verification yourself:

First, build the bats testing container:

    cd test/
    ansible-container build

Now, run the tests:

    ansible-container run

Currently this test is expected to run manually on your host outside the OpenShift environment. Future enhancements would be to push this into OpenShift and run as a stand-alone container or OpenShift job. Potentially even spinning up a Jenkins to run a test pipeline.

## Troubleshooting

### Authentication error when pushing images

While pushing images to Openshift you may receive `unauthorized: authentication required` this can sometimes result from previously stored login information that is now incorrect. This state can result from spinning up and down the cluster for testing. Either edit `~/.docker/config.yml` and remove the entry for the Openshift registry being pushed to or remove the file entirely.


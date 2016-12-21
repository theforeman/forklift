# Foreman on OpenShift

## NOTE: THIS IS NOT FOR PRODUCTION

The following is currently a proof of concept for running Foreman, Katello and the backend systems therein on OpenShift. This currently uses repository forks with patches, as well as security and data persistence compromises to achieve this. There is a list of to-dos at the bottom of this README that outlines next steps to get this closer to both production and developer readiness.

## Setup and Installation of OpenShift

This setup requires access to OpenShift 3.2 or later. The easiest way to run and play with this locally is to use the OpenShift Origin client tools 1.3+ and docker. This short guide will run through setting up a local test environment.

This setup guide was written using Fedora 23 but newer version of Fedora or Centos 7+ should work.


### Install Ansible

Parts of the setup have been automated using Ansible to ensure consistency and speed up getting to the deployment aspect. Please ensure you have Ansible installed:

Using yum:

    sudo yum install ansible

Using pip:

    sudo pip install ansible

### Setup Docker

First, ensure that docker is installed.

    sudo yum install docker

Second, we need to allow for insecure registries to run. This can be enabled by editing `/etc/sysconfig/docker` and adding:

    other_args='--insecure-registry 172.30.0.0/16'

Now restart the docker service:

    sudo systemctl restart docker

### Setup OpenShift Client Tools

The ability to spin up an OpenShift cluster on docker was added to OpenShift Client Tools v1.3+. This has been abstracted into an Ansible playbook for your convenience.

    ansible-playbook install-openshift-tools.yml

You can change the version of the OpenShift Client Tools that are installed by editing the playbook or passing variables to the `ansible-playbook` command.

### Setup OpenShift

Now that we have docker and the appropriate client tools setup we can spin up a docker based OpenShift cluster:

    oc cluster up

Enable privileged user access inside containers:

    oadm policy add-scc-to-group anyuid system:authenticated

Or use the all-in-one playbook to do this:

    ansible-playbook cluster-up.yml

## Creating the Foreman Deployment

There are two aspects to the deployment: the default images and templates being loaded into OpenShift and creating the Foreman deployment. All of this is handled by a convenient playbook provided. You can view the configuration of the Foreman deployment itself by looking in the `templates/foreman.yaml` file. To create the application:

    ansible-playbook create.yml

This step will create a new OpenShift project named Foreman, load into the default image streams and templates from the `openshift-ansible` repository. Then, two applications will be created. The first is an ephemeral Postgres database using the default templates provided by OpenShift. The second is the Foreman application itself which will build a Foreman image and then deploy it.

## Available Deployments

The repository provides the ability to deploy the applications associated with Foreman and Katello as stand alone projects as well as the entire kitchensink. 

  * Foreman
  * Foreman with Katello
  * Pulp
  * Candlepin
  * Qpid

## TODOs

 * shared mount point across Pulp workers and Pulp server instance
 * add pulp_streamer and squid services
 * solve Pulp journald logging (and remove use of Stream handler hack on my fork)
 * use separate database for Candlepin
 * move away from basic auth for Pulp to cert auth
 * run foreman-tasks in its own container
 * add qpid connection to Candlepin
 * add qpid connection to Katello
 * use persistent Postgras
 * add goferd service for clients
 * add foreman-proxy deployment
 * add qdrouterd for client connections

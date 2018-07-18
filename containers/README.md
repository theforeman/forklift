# Foreman on OpenShift

## NOTE: THIS IS NOT FOR PRODUCTION (yet)

The following is currently a proof of concept for running Foreman, Katello and the backend systems on OpenShift. This currently uses repository forks with patches, as well as security and data persistence compromises to achieve this. There is a list of to-dos at the bottom of this README that outlines next steps to get this closer to both production and developer readiness.

Table of Contents

 * [Build](./docs/build.md)
 * [Deploy](#quick-start-guide)
 * [Environment](./docs/environment.md)
 * [Architecture](./docs/architecture.md)
 * [Issues to be Addressed](#issues)

For diagrams outlining the architecture, please see the diagrams in the `docs/` folder.

## Quick Start Guide

This guide assumes that you are in the `containers/` folder for all operations.

This quickstart guide requires that the following are installed already:

 * [Ansible 2.6+](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
 * [Minishift](https://docs.openshift.org/latest/minishift/getting-started/installing.html)
   * Alternatively, minishift can be installed with our playbook: `ansible-playbook tools/install-minishift.yml`
 * [Openshift Rest Client 6.0+](https://github.com/openshift/openshift-restclient-python)

System Requirements:

 * 10GB RAM free

### Start Minishift

The minishift setup requires some customization due to resource requirements. Run the following to start minishift:

    minishift start --memory 10GB --cpus 4 --iso-url centos

A playbook is also provided that can be used:

    ansible-playbook tools/minishift-start.yml

Ensure you login to minishift to start:

    oc login -u developer -p a

Set the context for the Openshift client to talk to minishift:

    eval $(minishift oc-env)

### Deploy Application

First, create a new project:

    oc new-project foreman

Now login as the system admin to install the RBAC and custom resource definition:

    oc login -u system:admin

    oc create -f deploy/rbac.yaml
    oc create -f deploy/crd.yaml

For minishift, the developer user needs access to the Foreman custom resource definition:

    oc create -f deploy/developer-rbac.yaml

Once minishift is up and running, the application can be deployed. This is done by running a playbook:

    ansible-playbook deploy.yaml

The deployment takes a while the first time so be patient. The health and status of the deployment can be checked by running:

    ./test/test.rb

Once services are up and the health check returns OK for all services the application is available. To get the hostname run:

    oc get routes

Using the entry under HOST/PORT you can now browse to `https://<hostname>` and access the Foreman web UI.


#### Enabling specific services

By default the deployment playbook will deploy Foreman, PostgreSQL, Puppet, Pulp, Candlepin, Qpid. You can specify which of these components you want to deploy with the `enabled_services` variable. For example, to deploy only Foreman, PostgreSQL, and Puppet, run:

    ansible-playbook foreman.yml -e enabled_services=postgres,puppet

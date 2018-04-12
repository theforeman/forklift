# Foreman on OpenShift

## NOTE: THIS IS NOT FOR PRODUCTION (yet)

The following is currently a proof of concept for running Foreman, Katello and the backend systems on OpenShift. This currently uses repository forks with patches, as well as security and data persistence compromises to achieve this. There is a list of to-dos at the bottom of this README that outlines next steps to get this closer to both production and developer readiness.

Table of Contents

 * [Build](./docs/build.md)
 * [Deploy](./docs/deploy.md)
 * [Environment](./docs/environment.md)
 * [Architecture](./docs/architecture.md)
 * [Issues to be Addressed](#issues)

For diagrams outlining the architecture, please see the diagrams in the `docs/` folder.

## Quick Start Guide

This guide assumes that you are in the `containers/` folder for all operations.

This quickstart guide requires that the following are installed already:

 * [Ansible](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
 * [Minishift](https://docs.openshift.org/latest/minishift/getting-started/installing.html)

In addition the following steps need to be taken to install a few dependencies:

    pip install openshift
    ansible-galaxy install -r requirements.yml

System Requirements:

 * 10GB RAM free

### Start Minishift

The minishift setup requires some customization due to resource requirements. Run the following to start minishift:

    minishift start --memory 10GB --cpus 4 --iso-url centos

A playbook is also provided that can be used:

    ansible-playbook tools/minishift-start.yml

Set the context for the Openshift client to talk to minishift:

    eval $(minishift oc-env)

### Deploy Application

Once minishift is up and running, the application can be deployed. This is done by running a playbook:

    ansible-playbook foreman.yml --tags start

The deployment takes a while the first time so be patient. The health and status of the deployment can be checked by running:

    ./test/test.rb

Once services are up and the health check returns OK for all services the application is available. To get the hostname run:

    oc get routes

Using the entry under HOST/PORT you can now browse to `https://<hostname>` and access the Foreman web UI.

### Troubleshooting

#### UI Not Accessible

Sometimes when access to the UI fails, this is due to the `httpd` pod starting incorrectly.

##### Fix via UI Console

Browse the the Openshift console found at `https://$(minishift ip):8443/`. Login as `developer` with password `a` and browse to Applications > Pods. Find the httpd pod, select it, click on the Logs tab. If there is no output, browse to Applications > Deployments. Click on the httpd deployment, and click `deploy` in the upper right hand corner. Re-test the health check.

##### Fix via Command Line

The `httpd` container logs can be viewed on the command line. Find the httpd pod first:

    oc get pods

A pod should exist of the format `httpd-<id>`, view the logs:

    oc logs httpd-<id>

If this output is blank, the `httpd` container needs to be restarted:

    oc rollout latest dc/httpd

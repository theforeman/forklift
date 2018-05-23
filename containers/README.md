# Foreman on Docker

The following use case introduces a way for developers to run `Foreman` using `Docker`.

## Prerequisites

* Docker version `18.03.1-ce` although old versions probably work too
* Ansible `2.5.2`

## Overview

In general, to run `Foreman` from source:
1) `Foreman` has to be `git-clone`-ed from Github
2) binaries such as `ruby` and `nodejs` should be installed (step 1)
3) node packages and ruby gems have to be downloaded (step 2)
4) database migration and population should be executed to setup `Foreman` for the first time (step 3)

To make this process easy for developers the last three tasks were automated using `Ansible`.

## Cloning Foreman

If you have `Foreman`, then jump to **Step 1**.
Otherwise, `git clone https://github.com/theforeman/foreman.git` to `${HOME}`.

## Step 1: Building the development image

**Note**: `<foreman_path>` should be replaced with the path to the cloned `Foreman` mentioned above. For example, if you cloned `Foreman` to `${HOME}` then `<foreman_path>` should be set to `${HOME}/foreman`.

In this step, a new image based on `Fedora 27` is being built. That image includes all the binaries that are necessary
to setup and run `Foreman`.

To build the image run the following command

```bash
cd forklift/containers
cd ansible-playbook -t build -e "foreman_src=<foreman_path>" development.yml
```

**Note**: If `foreman_src` variable is not set using `-e` Ansible sets it to `${HOME}/foreman` by default.

What is going to happen is a new image called `local:devel` is going to be built from
[this Dockerfile](images/services/foreman/Dockerfile).

## Step 2: Install packages

In step 1 during the build process, a non root user was created.
That user has the same user and group IDs that you're using on the host machine. The reason for that is:
 1) It is always a good practice to run as non-root
 2) Files are going to be added to `foreman_src` and we would like the owner of those files to be the same one on the host.

In this step, node packages are going to be installed in `{{foreman_src}}/node_modules` and the rubygems packages are going to be installed in `{{foreman_src}}/gems`. By doing this, the "state" of the Foreman dependencies is controlled within your development directory and you can run `Foreman` in any new container without `bundle install` or `npm install` again.

To run this step enter the following command (assuming you're in the `containers` directory)

```bash
ansible-playbook -t install -e "foreman_src=<foreman_path>" development.yml
```

## Step 3: Database setup

This last step is running all the necessary setups on the database.
It basically executes database migration and seeds the database.

In case you're using `sqlite` locally then the changes are done in `{{foreman_src}}/db` or where you specified in `foreman_src/config/database.yml`.

In case you're using the `postgresql` adapter, a new container will be deployed with postgres database running in the background.

**Note**: Changing the `development` section in `foreman_src/config/database.yml` may cause running a new container which ends up with deleting the data on the database.
**Note**: Right now `mysql` and `mysql2` adapters are not supported but will be added soon.

Run the following command to execute this step:

```bash
ansible-playbook -t db_setup -e "foreman_src=<foreman_path>" development.yml
```

## Running Foreman

After getting these steps, you can run `Foreman` in a container by executing

```bash
ansible-playbook -t run -e "foreman_src=<foreman_path>" development.yml
```

You can open the browser and go to `localhost:5000` to login `Foreman`.

You can even see the logs inside the container by running

```bash
docker logs -f foreman_devel
```

To restart the container again, run the same command:

```bash
ansible-playbook -t run -e "foreman_src=<foreman_path>" development.yml
```

## Future

* Add `mysql` and `mysql2` support
* Add Foreman Proxy
* Explain how to add plugins
* Updating `foreman` may require doing `bundle update` and `bundle install`

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

 * [Ansible](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
 * [Minishift](https://docs.openshift.org/latest/minishift/getting-started/installing.html)

In addition the following steps need to be taken to install a few dependencies:

    pip install git+https://github.com/ehelms/openshift-restclient-python.git@fix-destination-ca
    ansible-galaxy install -r requirements.yml

Note that the special version of the OpenShift python client is needed for this [fix](https://github.com/openshift/openshift-restclient-python/pull/166).

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

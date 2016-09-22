# Development Environments

This covers how to setup and configure a development environment using the Forklift tool suite.

 * [Development Environment Deployment](#development-environment-deployment)
 * [Use Koji Scratch Builds](#koji-scratch-builds)
 * [Test Puppet Module Pull Requests](#testing-module-pull-requests)
 * [Jenkins Job Builder](#jenkins-job-builder-development)
 * [Redmine Development](#redmine-development)
 * [Hammer Development](#hammer-development)
 * [Capsule Development](#capsule-development)
 * [Client Development](#client-development)

## Development Environment Deployment

A Katello development environment can be deployed on CentOS 6 or 7. Ensure that you have followed the steps to setup Vagrant and the libvirt plugin. There are a variety of useful development environment options that should or can be set when creating a development box. These options are designed to configure your environment ready to use your own fork, and create pull requests. To create a development box:

  1. Copy `boxes.yaml.example` to `boxes.yaml`. If you already have a `boxes.yaml`, you can copy the entries in `boxes.yaml.example` to your `boxes.yaml`.
  2. Now, replace `<my_github_username>` with your github username
  3. Fill in any other options, examples:
    * `--katello-devel-use-ssh-fork`: will add your fork by SSH instead of HTTPS
    * `--katello-devel-fork-remote-name`: will change the naming convention for your fork's remote
    * `--katello-devel-upstream-remote-name`: will change the naming convention for the upstream (non-fork) repositories remote
    * `--katello-devel-extra-plugins`: specify other plugins to have setup and configured

For example, if I wanted my upstream remotes to be origin and to install the remote execution and discovery plugins:

```
centos7-devel:
  box: centos7
  shell: 'yum -y install ruby && cd /vagrant && ./setup.rb'
  options: --scenario=katello-devel
  installer: --katello-devel-github-username myname --katello-devel-upstream-remote-name origin --katello-devel-extra-plugins theforeman/foreman_remote_execution --katello-devel-extra-plugins theforeman/foreman_discovery
```

Lastly, spin up the box:

```
vagrant up centos7-devel
```

The box can now be accessed via ssh and the Rails server started directly (this assumes you are connecting as the default `vagrant` user):

    vagrant ssh <deployment>
    cd /home/vagrant/foreman
    sudo service iptables stop
    bin/rails s -b 0.0.0.0


## Koji Scratch Builds

The setup.rb script supports using Koji scratch builds to make RPMs available for testing purposes. For example, if you want to test a change to nightly, with a scratch build of rubygem-katello. This is done by fetching the scratch builds, and deploying a local yum repo to the box you are deploying on. Multiple scratch builds are also supported for testing changes to multiple components at once (e.g. the installer and the rubygem), see examples below. Also, this option may be specified from within boxes.yaml via the `options:` option.

Single Scratch Build

```
./setup.rb --koji-task 214567
```

Multiple Scratch Builds

```
./setup.rb --koji-task 214567,879567,2747127
```

Custom Box
```
koji:
  box: centos6
  options: --koji-task 214567,879567
```

An Ansible role is provided that can setup and configure a Koji scratch build for testing. If you had an existing playbook such as:

```
- hosts: server
  roles:
    - etc_hosts
    - foreman_repositories
    - katello_repositories
    - katello
```

The Koji role and task ID variable can be added to download and configure a repository with priority:

```
- hosts: server
  vars:
    koji_task_id: 321231
  roles:
    - etc_hosts
    - koji
    - foreman_repositories
    - katello_repositories
    - katello
```

## Testing Module Pull Requests

The setup.rb script supports specifying any number of modules and associated pull requests for testing. For example, if a module under goes a refactoring, and you want to test that it continues to work with the installer. You'll need the name of the module and the pull request number you want to test. Note that the name in this situation is the name as laid down in the module directory as opposed to the github repository name. In other words, use 'qpid' not 'puppet-qpid'. Formatting requires the module name followed by a '/' and then the pull request number. See examples below.

Note that you'll need a checkout of [katello-installer](https://github.com/Katello/katello-installer) as a subdirectory in forklift:
```
git clone https://github.com/Katello/katello-installer.git
```

Single module PR:
```
./setup.rb --module-prs qpid/12
```

Multiple modules:
```
./setup.rb --module-prs qpid/12,katello/11
```

Custom Box:
```
module_test:
  box: centos6
  options: --module-prs qpid/12
```

## Jenkins Job Builder Development

When modifying or creating new Jenkins jobs, it's helpful to generate the XML file to compare to the one Jenkins has. In order to do this, you need a properly configured Jenkins Job Builder environment. The dockerfile under docker/jjb can be used as a properly configured environment. To begin, copy `docker-compose.yml.example` to `docker-compose.yml`:

```
cd docker/jjb
cp docker-compose.yml.example docker-compose.yml
```

Now edit the docker-compose configuration file to point at your local copy of the `foreman-infra` repository so that it will mount and record changes locally when working within the container. Ensure that either your docker has permissions to the repository being mounted or that the appropriate Docker SELinux context is set: [Docker SELinux with Volumes](http://www.projectatomic.io/blog/2015/06/using-volumes-with-docker-can-cause-problems-with-selinux/). Now we are ready to do any Jenkins Job Builder work. For example, if you wanted to generate all the XML files for all jobs:

```
docker-compose run jjb bash
cd foreman-infra/puppet/modules/jenkins_job_builder/files/theforeman.org
jenkins-jobs -l debug test -r . -o /tmp/jobs
```

## Redmine Development

The Foreman project uses Redmine to handle issue management via forked instance of Redmine that runs on Openshift. Testing upgrades, making plugins or patches is sometimes desired to achieve functionality which we need. The dockerfile under docker/redmine can be used as a properly configured Redmine environment for development. To begin, copy `docker-compose.yml.example` to `docker-compose.yml`:

```
cd docker/redmine
cp docker-compose.yml.example docker-compose.yml
```

Assuming you have a clone of the Redmine repository somewhere locally, edit the `docker-compose.yml` configuration file to point at your local copy of the `redmine` repository so that it will mount and record changes locally when working within the container. Ensure that either your docker has permissions to the repository being mounted or that the appropriate Docker SELinux context is set: [Docker SELinux with Volumes](http://www.projectatomic.io/blog/2015/06/using-volumes-with-docker-can-cause-problems-with-selinux/). Now we are ready to start up Redmine and make changes:

```
docker-compose up redmine
```

## Hammer Development

Hammer is the command line interface (CLI) to Foreman and Katello. It supports plugins
such as [Foreman Tasks](https://github.com/theforeman/hammer-cli-foreman-tasks) and
importing/exporting data via [CSV](https://github.com/Katello/hammer-cli-csv).
The CLI can be configured to work with any version of Foreman. To facilitate
development in Hammer or any of its plugins, a lightweight vagrant box is
provided in this repository:

```sh
vagrant up centos7-hammer-devel
```

In the vagrant box, find the Hammer repositories at `/home/vagrant/` and the
configuration at `/home/vagrant/.hammer`. Specifically, to change the Foreman
instance Hammer points to, update
`/home/vagrant/.hammer/cli.modules.d/foreman.yml`.

## Capsule Development

To use this functionality, add the following configuration to your boxes.yaml,
changing the hostnames as needed

### To setup a capsule and a new development environment

* setup boxes.yaml

```
foo:
  box: centos7
  shell: 'yum -y install ruby && cd /vagrant && ./setup.rb'
  options: --scenario=katello-devel
  installer: --katello-devel-github-username <your-github-name>
  ansible:
    group: 'server'

capsule-dev:
  box: centos7
  ansible:
    playbook: 'playbooks/capsule-dev.yml'
    group: 'capsule'
    server: 'foo'
```
* ```vagrant up foo```
* ssh into foo and ```rails s```
* ```vagrant up capsule-dev```


### To setup a capsule with an existing development environment

* Add the following to the existing Katello development server's configuration in boxes.yaml
```
  ansible:
    group: 'server'
```
* Add a box for a capsule, using the katello server's name in the "server" field:

```
capsule-dev:
  box: centos7
  ansible:
    playbook: 'playbooks/capsule-dev.yml'
    group: 'capsule'
    server: 'your-katello-server-name'
```
* ssh into existing development server and ```rails s```
* spin up new capsule ```vagrant up capsule-dev```

## Client Development

In boxes.yaml:

Add your client, replacing 'your-katello-server-name' with your main katello development server name

```
client1:
  box: centos7
  ansible:
    playbook: 'playbooks/katello_client.yml'
    group: 'client'
    server: 'your-katello-server-name'
```

then add

```
  ansible:
    group: 'server'
```

to the main katello server you want the client attached to

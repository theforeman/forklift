# Forklift

This repository provides methods to easily test and deploy a Foreman or Katello server. There are two
different types of setups&mdash;nightly and development. The latter is for setting up Foreman/Katello from git repositories so that you can contribute to Foreman, Katello or any other plugins. Nightly installs are production installs from the nightly RPMs that contain the bleeding edge code.

In terms of the type of deployments, there are also two options: VM and direct. Using Vagrant will
automatically provision the VM with VirtualBox or libvirt while a direct deployment assumes you are
not using a VM or you already have the VM created. Check the table below to verify which operating
system you can use for which type of deployment.

| OS        | Production |Nightly | Development | Direct | Vagrant |
|-----------|:-----------|:-------|:------------|:-------|:--------|
| CentOS 6  | X          | X      | X           | X      | X       |
| CentOS 7  | X          | X      | X           | X      | X       |
| RHEL 6    | X          | X      | X           | X      |         |
| RHEL 7    | X          | X      | X           | X      |         |


## Vagrant Deployment

A Vagrant deployment will provision either a development setup (using git repositories) or an
install using the nightly RPMs.

The first step in using Vagrant to deploy an environment is to ensure that Vagrant and this repository are installed and setup. To do so:

1. Ensure you have Vagrant installed
   * For **libvirt**:
     1. Ensure you have the prerequisites installed `sudo yum install ruby rubygems ruby-devel gcc`
     2. Vagrant 1.6.5+ can be downloaded and installed from [Vagrant Downloads](http://www.vagrantup.com/downloads.html)
   * For **Virtualbox**, Vagrant 1.6.5+ can be downloaded and installed from [Vagrant Downloads](http://www.vagrantup.com/downloads.html)
1. Clone this repository - `git clone https://github.com/Katello/forklift.git`
1. Enter the repository - `cd forklift`

### Using VirtualBox (Windows, OS X)

If you're using Linux, we recommend libvirt (see next section). The default setup in the Vagrantfile is for VirtualBox.
It has been tested against VirtualBox 4.2.18.  To use Install VirtualBox from [the 4.2 downloads
page](https://www.virtualbox.org/wiki/Download_Old_Builds_4_2)

### Using Libvirt (Linux)

The Vagrantfile provides default setup and boxes for use with the `vagrant-libvirt` provider. To set this up:

1. Install libvirt. On CentOS/Fedora/RHEL, run `sudo yum install @virtualization libvirt-devel`
1. Install the libvirt plugin for Vagrant (see [vagrant-libvirt page](https://github.com/pradels/vagrant-libvirt#installation) for more information) `vagrant plugin install vagrant-libvirt`
1. Make sure your user is in the `qemu` group. (e.g. `[[ ! "$(groups $(whoami))" =~ "qemu" ]] && sudo usermod -aG qemu $(whoami)`)
1. Set the libvirt environment variable in your `.bashrc` or for your current session - `export VAGRANT_DEFAULT_PROVIDER=libvirt`
1. If you are asked to provide your password for every command, follow [these policykit steps](http://fedoramagazine.org/running-vagrant-fedora-22/).

### Nightly Production Install

Currently Katello is only available in the Katello nightly repositories. Provided
is a Vagrant setup that will setup and install Katello on a CentOS box. Any base CentOS box and Vagrant
setup should work but we have been testing and using Vagrant with libvirt.

Start the installation for CentOS 6:

    vagrant up centos6-nightly

Start the installation for CentOS 7:

    vagrant up centos7-nightly

This will create a libvirt based virtual machine running the Katello server on CentOS.

### Development Deployment

A Katello development environment can be deployed on CentOS 6 or 7. Ensure that you have followed the steps to setup Vagrant and the libvirt plugin. There are a variety of useful development environment options that should or can be set when creating a development box. These options are designed to configure your environment ready to use your own fork, and create pull requests. To create a development box:

  1. Copy boxes.yaml.example to boxes.yaml. If you already have a boxes.yaml, you can copy the entries in boxes.yaml.example to your boxes.yaml.
  2. Now, replace <my_github_username> with your github username
  3. Fill in any other options, examples:
    * --katello-devel-use-ssh-fork: will add your fork by SSH instead of HTTPS
    * --katello-devel-fork-remote-name: will change the naming convention for your fork's remote
    * --katello-devel-upstream-remote-name: will change the naming convention for the upstream (non-fork) repositories remote
    * --katello-devel-extra-plugins: specify other plugins to have setup and configured

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

### Adding Custom Boxes

Sometimes you want to spin up the same box type (e.g. centos7-devel) from within the forklift directory. While this can be added to the Vagrantfile directly, updates to the forklift repository could wipe out your local changes. To help with this, you can define a custom box re-using the configuration within the Vagrantfile. To do so, create a `boxes.yaml` file. For example, to create a custom box on CentOS 7 with nightly and run the installers reset command:

```
my-nightly-test:
  box: centos7
  installer: '--reset'
```

Options:

```
box -- the ':name' one of the defined boxes in the Vagrantfile
installer -- options that you would like passed to the installer
options -- options that setup.rb accepts, e.g. --skip-installer
shell -- customize the shell script run
bridged -- deploy on Libvirt with a bridged networking configuration, value of this parameter should be the interface of the host (e.g. em1)
memory -- set the amount of memory (in megabytes) this box will consume
cpus -- set the number of cpus this box will use
hostname -- hostname to set on the box
networks -- custom networks to use in addition to the management network
```

Entirely new boxes can be created that do not orginate from a box defined within the Vagrantfile. For example, if you had access to a RHEL Vagrant box:

```
rhel7:
  box_name: rhel7
  shell: 'echo TEST'
  pty: true
  libvirt: http://example.org/vagrant/rhel-7.box
```

Example with custom networking, static IP on custom libvirt network:

```
static:
  box: centos7
  hostname: mystatic.box.com
  networks:
    - type: 'private_network'
      options:
        ip: 192.168.150.3
        libvirt__network_name: lab-private
        libvirt__iface_name: vnet2
```

### Plugins

Any file on path `./plugins/*/Vagrantfile` will be loaded on `./Vagrantfile` evaluation. `plugins` directory is ignored by git therefore other git repositories can be cloned into `plugins` to add custom machines.

Example of a plugin's `Vagrantfile`:

```ruby
module APlugin

  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    DB           = 'db'
    WEB          = 'web'
    PARENT_NAME  = 'centos6-devel'
    PROJECT_PATH = "#{Forklift::ROOT}/../a_repo"

    Forklift.define_vm config, Forklift.new_box(PARENT_NAME, DB) do |machine|
      machine.vm.provision :shell do |shell|
        shell.inline = 'echo doing DB box provisioning'
        config.vm.synced_folder PROJECT_PATH, "/home/vagrant/a_repo"
        config.vm.provider :virtualbox do |domain|
          domain.memory = 1024
        end
      end
    end

    Forklift.define_vm config, Forklift.new_box(PARENT_NAME, WEB) do |machine|
      machine.vm.provision :shell do |shell|
        shell.inline = 'echo doing WEB box provisioning'
        shell.inline = 'echo doing another WEB box provisioning'
        config.vm.synced_folder PROJECT_PATH, "/home/vagrant/a_repo"
        config.vm.provider :virtualbox do |domain|
          domain.memory = 512
        end
      end
    end
  end
end
```

If you would like to inject hostname management and package caching without
updating the base Vagrantfile,  you can install the `vagrant-hostname` and
`vagrant-cachier` plugins and then create
`./plugins/my-custom-plugins/Vagrantfile` with the following content:

```ruby

# this enables some customizations that should not be used until after you have a
# working basic install.

module MyCustomPlugins
  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    # set up some shared dirs
    config.vm.synced_folder "/path/to/local/checkout/katello", "/home/vagrant/share/katello", type: "nfs"
    config.vm.synced_folder "/path/to/local/checkout/foreman", "/home/vagrant/share/foreman", type: "nfs"
    config.vm.synced_folder "/path/to/local/checkout/foreman-gutterball", "/home/vagrant/share/foreman-gutterball", type: "nfs"

    if Vagrant.has_plugin?("vagrant-hostmanager")
      config.hostmanager.enabled = true
      config.hostmanager.manage_host = true
    end

    if Vagrant.has_plugin?("vagrant-cachier")
      # Configure cached packages to be shared between instances of the same base box.
      # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
      config.cache.scope = :box
      # disable gem caching for now, due to permissions issue
      config.cache.auto_detect = false
      config.cache.enable :yum

      config.cache.synced_folder_opts = {
        type: :nfs,
        mount_options: ['rw', 'vers=4', 'tcp', 'nolock']
      }
    end
  end
end
```

### Troubleshooting

#### vagrant-libvirt

If you have problems installing the libvirt plugin, be sure to checkout the [troubleshooting section](https://github.com/pradels/vagrant-libvirt#possible-problems-with-plugin-installation-on-linux) of their README.

#### selinux

If you get this error:

```
There was an error talking to Libvirt. The error message is shown
below:

Call to virDomainCreateWithFlags failed: Input/output error
```

The easiest thing to do is disable selinux using: `sudo setenforce 0`.  Alternatively you can configure libvirt for selinux, see http://libvirt.org/drvqemu.html#securitysvirt

#### nfs

If you get this error:

```
mount.nfs: rpc.statd is not running but is required for remote locking.
mount.nfs: Either use '-o nolock' to keep locks local, or start statd.
mount.nfs: an incorrect mount option was specified
```

Make sure nfs is installed and running:

```
sudo yum install nfs-utils
sudo service start nfs-server
```

#### low disk space

Your OS may be installed with a large root parition and smaller `/home`
partition. Vagrant will populate `~/.vagrant.d/` with boxes by default; each of
which can be over 2GB in size. This may cause disk space issues on your `/home`
partition.

To store your Vagrant files elsewhere, you can create a directory outside of
`/home` and tell Vagrant about it by setting `VAGRANT_HOME=<path to vagrant
dir>`. You may need to set this in your `.bash_profile` so it persists between
logins.


## Direct Deployment

This setup assumes you are either deploying on a non-VM environment or you
already have a VM setup and are logged into that VM.

### RHEL Prerequisites

If on RHEL, it is assumed you have already registered and subscribed your system.

```
subscription-manager register --username USER --password PASSWORD --auto-attach
```

### Deployment

1. ssh to target machine **as root**
2. Install git and ruby - `yum install -y git ruby`
3. Clone this repository - `git clone https://github.com/Katello/forklift.git`
4. Enter the repository - `cd forklift`

For a release version in production:

    ./setup.rb --version 2.2

For nightly production:

    ./setup.rb

For development:

    ./setup.rb --install-type=devel --devel-user=username

## Bats Testing

Included with forklift is a small live test suite.  The current tests are:

  * fb-install-katello.bats - Installs katello and runs a few simple tests

To execute the bats framework:

 * Using vagrant (after configuring vagrant according to this document):
  1.  vagrant up centos6-bats
  2.  vagrant ssh centos6-bats -c 'sudo fb-install-katello.bats'

 * On a fresh system you've manually installed:
  1.  ./bats/bootstrap.sh
  2.  katello-bats

## Run Scripts Post Install

User defined scripts can be run after a successful installation to facilitate common per user actions. For example, if there are common setup tasks run on every devel box for a user these can be setup to run for every run of `setup.rb`. This also translates to running on every up/provision when using Vagrant. To define a script to be run, create a `scripts/` directory and then place the script inside. For example, if you wanted to have `vim` installed on every box, make a file `scripts/vim.sh`:

```
#!/bin/bash

yum -y install vim
```

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

## Testing Module Pull Requests

The setup.rb script supports specifying any number of modules and associated pull requests for testing. For example, if a module under goes a refactoring, and you want to test that it continues to work with the installer. You'll need the name of the module and the pull request number you want to test. Note that the name in this situation is the name as laid down in the module directory as opposed to the github repository name. In other words, use 'qpid' not 'puppet-qpid'. Formatting requires the module name followed by a '/' and then the pull request number. See examples below.

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

## Client Testing With Docker

The docker/clients directory contains setup and configuration to register clients via subscription-manager using an activation key and start katello-agent. Before using the client containers, Docker and docker-compose need to be installed and setup. On a Fedora based system (Fedora 20 or greater):

```
sudo yum install docker
sudo service docker start
sudo chkconfig docker on
sudo usermod -aG docker your_username

curl -L https://github.com/docker/compose/releases/download/VERSION_NUM/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

For other platforms see the official instructions at:

 * [docker](https://docs.docker.com/installation/)
 * [docker-compose](https://docs.docker.com/compose/install/)

In order to use the client containers you will also need the following:

 * Foreman/Katello server IP address
 * Foreman/Katello server hostname
 * Foreman Organization
 * Activation Key
 * Katello version you have deployed (e.g. nightly, 2.2)

Begin by changing into the docker/clients directory and copying the `docker-compose.yml.example` file to `docker-compose.yml` and filling in the necessary information gathered above. At this point, you can now spin-up one or more clients of varying types. For example, if you wanted to spin up a centos6 based client:

```
docker-compose up el6
```

If you want to spin up more than one client, let's say 10 for this example, the docker-compose scale command can be used:

```
docker-compose scale el6=10
```

## Jenkins Job Builder Development

When modifying or creating new Jenkins jobs, it's helpful to generate the XML file to compare to the one Jenkins has. In order to do this, you need a properly configured Jenkins Job Builder environment. The dockerfile under docker/jjb can be used as a properly configured environment. To begin, copy `docker-compose.yml.example` to `docker-compose.yml`:

```
cd docker/jjb
cp docker-compose.yml.example docker-compose.yml
```

Now edit the docker-compose configuration file to point at your local copy of the `foreman-infra` repository so that it will mount and record changes locally when working within the container. Ensure that either your docker has permissions to the repository being mounted or that the appropriate Docker SELinux context is set: (Docker SELinux with Volumes)[http://www.projectatomic.io/blog/2015/06/using-volumes-with-docker-can-cause-problems-with-selinux/]. Now we are ready to do any Jenkins Job Builder work. For example, if you wanted to generate all the XML files for all jobs:

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

Assuming you have a clone of the Redmine repository somewhere locally, edit the `docker-compose.yml` configuration file to point at your local copy of the `redmine` repository so that it will mount and record changes locally when working within the container. Ensure that either your docker has permissions to the repository being mounted or that the appropriate Docker SELinux context is set: (Docker SELinux with Volumes)[http://www.projectatomic.io/blog/2015/06/using-volumes-with-docker-can-cause-problems-with-selinux/]. Now we are ready to start up Redmine and make changes:

```
docker-compose up redmine
```

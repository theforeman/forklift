# Katello Deployment

This repository provides methods to easily test and deploy a Katello server.  There are two
different types of setups&mdash;nightly and development. The latter is for setting up Katello from
git repositories so that you can contribute to Katello. Nightly installs are production installs
from the nightly RPMs that contain the bleeding edge Katello code.

In terms of the type of deployments, there are also two options: VM and direct. Using Vagrant will
automatically provision the VM with VirtualBox or libvirt while a direct deployment assumes you are
not using a VM or you already have the VM created. Check the table below to verify which operating
system you can use for which type of deployment.

| OS        | 2.0 |Nightly | Development | Direct | Vagrant |
|-----------|:----|:-------|:------------|:-------|:--------|
| CentOS 6  | X   | X      | X           | X      | X       |
| CentOS 7  | X   | X      | X           | X      | X       |
| RHEL 6    | X   | X      | X           | X      |         |
| RHEL 7    | X   | X      | X           | X      |         |


## Vagrant Deployment

A Vagrant deployment will provision either a development setup (using git repositories) or an
install using the nightly RPMs.

The first step in using Vagrant to deploy a Katello environment is to ensure that Vagrant and this repository are installed and setup. To do so:

1. Ensure you have Vagrant installed
   * For **libvirt**:
     1. Ensure you have the prerequisites installed `sudo yum install ruby rubygems gcc`
     2. Vagrant 1.6.5+ can be downloaded and installed from [Vagrant Downloads](http://www.vagrantup.com/downloads.html)
   * For **Virtualbox**, Vagrant 1.6.5+ can be downloaded and installed from [Vagrant Downloads](http://www.vagrantup.com/downloads.html)
1. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
1. Enter the repository - `cd katello-deploy`

### Using VirtualBox (Windows, OS X)

If you're using Linux, we recommend libvirt (see next section). The default setup in the Vagrantfile is for VirtualBox.
It has been tested against VirtualBox 4.2.18.  To use Install VirtualBox from [the 4.2 downloads
page](https://www.virtualbox.org/wiki/Download_Old_Builds_4_2)

### Using Libvirt (Linux)

The Vagrantfile provides default setup and boxes for use with the `vagrant-libvirt` provider. You need to use 0.0.20 of the vagrant-libvirt plugin. To set this up:

1. Install libvirt. On CentOS/Fedora/RHEL, run `sudo yum install @virtualization libvirt-devel`
1. Install the libvirt plugin for Vagrant (see [vagrant-libvirt page](https://github.com/pradels/vagrant-libvirt#installation) for more information) `vagrant plugin install vagrant-libvirt --plugin-version 0.0.20`
1. Make sure your user is in the `qemu` group. (e.g. `[[ ! "$(groups $(whoami))" =~ "qemu" ]] && sudo usermod -aG qemu $(whoami)`)
1. Set the libvirt environment variable in your `.bashrc` or for your current session - `export VAGRANT_DEFAULT_PROVIDER=libvirt`

### Nightly Production Install

Currently Katello is only available in the Katello nightly repositories. Provided
is a Vagrant setup that will setup and install Katello on a CentOS box. Any base CentOS box and Vagrant
setup should work but we have been testing and using Vagrant with libvirt.

Start the installation for CentOS 6:

    vagrant up centos6

Start the installation for CentOS 7:

    vagrant up centos7

This will create a libvirt based virtual machine running the Katello server on CentOS.

### Development Deployment

A Katello development environment can be deployed on CentOS 6 or 7. Ensure that you have followed the steps to setup Vagrant and the libvirt plugin.

To deploy to CentOS 6:

    vagrant up centos6-devel

To deploy to CentOS 7:

    vagrant up centos7-devel

The box can now be accessed via ssh and the Rails server started directly:

    vagrant ssh <deployment>
    cd /home/vagrant/foreman
    sudo service iptables stop
    rails s

### Adding Custom Boxes

Sometimes you want to spin up the same box type (e.g. centos7-devel) from within the katello-deploy directory. While this can be added to the Vagrantfile directly, updates to the katello-deploy repository could wipe our your local changes. To help with this, you can define a custom box re-using the configuration within the Vagrantfile. To do so, create a `boxes.yaml` file. For example, to create a custom box on CentOS 7 with nightly and run the installers reset command:

```
my-nightly-test:
  box: centos7
  installer: '--reset'
```

Options:

```
box -- the ':name' one of the defined boxes in the Vagrantfile
installer -- options that you would like passed to the katello-installer
options -- options that setup.rb accepts, e.g. --skip-installer
```

Entirely new boxes can be created that do not orginate from a box defined within the Vagrantfile. For example, if you had access to a RHEL Vagrant box:

```
rhel7:
  box_name: rhel7
  shell: 'echo TEST'
  pty: true
  libvirt: http://example.org/vagrant/rhel-7.box
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
    PROJECT_PATH = "#{KatelloDeploy::ROOT}/../a_repo"

    KatelloDeploy.define_vm config, KatelloDeploy.new_box(PARENT_NAME, DB) do |machine|
      machine.vm.provision :shell do |shell|
        shell.inline = 'echo doing DB box provisioning'
        config.vm.synced_folder PROJECT_PATH, "/home/vagrant/a_repo"
        config.vm.provider :virtualbox do |domain|
          domain.memory = 1024
        end
      end
    end

    KatelloDeploy.define_vm config, KatelloDeploy.new_box(PARENT_NAME, WEB) do |machine|
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
3. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
4. Enter the repository - `cd katello-deploy`

For a release version in production:

    ./setup.rb --version 2.0

For nightly production:

    ./setup.rb

For development:

    ./setup.rb --devel --devel-user=username

## Bats Testing

Included with katello-deploy is a small live test suite.  The current tests are:

  * fb-install-katello.bats - Installs katello and runs a few simple tests

To execute the bats framework:

 * Using vagrant (after configuring vagrant according to this document):
  1.  vagrant up centos6-bats
  2.  vagrant ssh centos6-bats -c 'sudo fb-install-katello.bats'

 * On a fresh system you've manually installed:
  1.  ./bats/bootstrap.sh
  2.  fb-install-katello.bats

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

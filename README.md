# Katello Deployment

This repository provides methods to easily test and deploy a Katello server.  There are two
different types of setups&mdash;nightly and development. The latter is for setting up Katello from
git repositories so that you can contribute to Katello. Nightly installs are production installs
from the nightly RPMs that contain the bleeding edge Katello code.

In terms of the type of deployments, there are also two options: VM and direct. Using Vagrant will
automatically provision the VM with VirtualBox or libvirt while a direct deployment assumes you are
not using a VM or you already have the VM created. Check the table below to verify which operating
system you can use for which type of deployment.

| OS        | Nightly | Development | Direct | Vagrant |
|-----------|:--------|:------------|:-------|:--------|
| CentOS 6  | X       | X           | X      | X       |
| RHEL 6    | X       | X           | X      |         |
| Fedora 19 |         | X           | X      | X       |


## Vagrant Deployment

A Vagrant deployment will provision either a development setup (using git repositories) or an
install using the nightly RPMs.

The first step in using Vagrant to deploy a Katello environment is to ensure that Vagrant and this repository are installed and setup. To do so:

1. Ensure you have Vagrant installed
   * For **libvirt**, download the approprite distribution package and install from [Vagrant 1.3.5 Download](http://downloads.vagrantup.com/tags/v1.3.5)
   * For **Virtualbox**, Vagrant 1.5+ can be downloaded and installed from [Vagrant 1.5 Download](http://www.vagrantup.com/downloads.html)
2. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
3. Enter the repository - `cd katello-deploy`

### Using VirtualBox (Windows, OS X)

If you're using Linux, we recommend libvirt (see next section). The default setup in the Vagrantfile is for VirtualBox.
It has been tested against VirtualBox 4.2.18.  To use Install VirtualBox from [the 4.2 downloads
page](https://www.virtualbox.org/wiki/Download_Old_Builds_4_2)

### Using Libvirt (Linux)

The Vagrantfile provides default setup and boxes for use with the `vagrant-libvirt` provider. You need to use 0.0.13 of the vagrant-libvirt plugin. To set this up:

1. Install libvirt. On CentOS/Fedora/RHEL, run `sudo yum install @virtualization libvirt-devel`
1. Install the libvirt plugin for Vagrant (see [vagrant-libvirt page](https://github.com/pradels/vagrant-libvirt#installation) for more information) `vagrant plugin install vagrant-libvirt --plugin-version 0.0.13`
1. Set the libvirt environment variable in your `.bashrc` or for your current session - `export VAGRANT_DEFAULT_PROVIDER=libvirt`

### Nightly Production Install

Currently Katello is only supported on EL6 and available in the Katello nightly repositories. Provided
is a Vagrant setup that will setup and install Katello on a CentOS box. Any base CentOS box and Vagrant
setup should work but we have been testing and using Vagrant with libvirt.

Start the installation:

    vagrant up centos

This will create a libvirt based virtual machine running the Katello server on CentOS.

### Development Deployment

A Katello development environment can be deployed on Centos or Fedora 19. Ensure that you have followed the steps to setup Vagrant and the libvirt plugin.

To deploy to Fedora 19:

    vagrant up f19-devel

To deploy to Centos:

    vagrant up centos-devel

The box can now be accessed via ssh and the Rails server started directly:

    vagrant ssh <deployment>
    cd /home/vagrant/foreman
    sudo service iptables stop
    rails s

### Troubleshooting

#### vagrant-libvirt

If you have problems installing the libvirt plugin, be sure to checkout the [troubleshooting section](https://github.com/pradels/vagrant-libvirt#possible-problems-with-plugin-installation-on-linux) of their README.

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

1. ssh to target machine as root
2. Install git and ruby - `yum install -y git ruby`
3. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
4. Enter the repository - `cd katello-deploy`

For nightly production:

    ./setup.rb [rhel6|centos6|fedora19]

For development:

    ./setup.rb --devel --devel-user=username [rhel6|centos6|fedora19]



# Katello Deployment

This repository provides methods to easily test and deploy a Katello server. 
Currently Katello is only supported on EL6 and available in the Katello nightly repositories.

Supported production environments:

  * EL6

Supported development environments:

  * EL6
  * Fedora 19

## Vagrant Deployment

The first step in using Vagrant to deploy a Katello environment is to ensure that Vagrant and this repository are installed and setup. To do so:

1. Ensure you have Vagrant installed, specifically version 1.3+ available from - http://downloads.vagrantup.com/tags/v1.3.5

## Using Libvirt

The Vagrantfile provides default setup and boxes for use with the `vagrant-libvirt` provider. To set this up:

1. Install the libvirt plugin for Vagrant (see vagrant plugin install vagrant-libvirt for more information) - `vagrant plugin install vagrant-libvirt`
2. Set the libvirt environment variables in your `.bashrc` or for your current session - `export VAGRANT_DEFAULT_PROVIDER=libvirt`
3. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
4. Enter the repository - `cd katello-deploy`

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

## Direct Deployment CentOS

This repository can also be used to setup and deploy directly on to a VM you have already spun up. From 
the VM itself:

1. ssh to target machine
2. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
3. Enter the repository - `cd katello-deploy`

For nightly production:

    ./bootstrap.sh centos

For development:

    ./bootstrap.sh centos --devel


## Direct Deployment RHEL 6.X

You can also deploy to an already running RHEL system.  Note you have to specify a Red Hat Portal username and password as well as a 'poolid' to subscribe your system to.

This poolid should grant you access to Red Hat Enterprise Linux and is found via the 'subscription-manager list --available' command, similar to:

```
# subscription-manager list --available
+-------------------------------------------+
    Available Subscriptions
+-------------------------------------------+
..
Subscription Name: Red Hat Enterprise Linux Server, Self-support (8 sockets) (Up to 1 guest)
SKU:               RH00000
Pool ID:           <YOUR POOLID HERE>
Quantity:          75
Service Level:     SELF-SUPPORT
Service Type:      L1-L3
Multi-Entitlement: No
Ends:              03/05/2014
System Type:       Physical
```

1. ssh to target machine
2. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
3. Enter the repository - `cd katello-deploy`
4. Run the bootstrap script `./bootstrap-rhel.sh <RH Portal Username> <RH Portal Password> <poolid>`


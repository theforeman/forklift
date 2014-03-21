# Katello Deployment

This repository provides methods to easily test and deploy a Katello server. 
Currently Katello is only supported on EL6 and available in the Katello nightly repositories.

## Vagrant Deployment

Currently Katello is only supported on EL6 and available in the Katello nightly repositories. Provided
is a Vagrant setup that will setup and install Katello on a CentOS box. Any base CentOS box and Vagrant 
setup should work but we have been testing and using Vagrant with libvirt. Thus, below are detailed instructions
for setup with libvirt.

1. Ensure you have Vagrant installed, specifically version 1.3+ available from - http://downloads.vagrantup.com/tags/v1.3.5
2. Follow the instructions to install the `vagrant-libvirt` plugin - http://downloads.vagrantup.com/tags/v1.3.5
3. Install the `centos64` box
4. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
5. Enter the repository - `cd katello-deploy`
6. Start the installation - `vagrant up centos`

This will create a libvirt based virtual machine running the Katello server on CentOS. Note that on step 6, other options besides `centos` would include `centos-devel` and `f19-devel`.

## Direct Deployment CentOS

This repository can also be used to setup and deploy directly on to a VM you have already spun up. From 
the VM itself:

1. ssh to target machine
2. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
3. Enter the repository - `cd katello-deploy`
4. Run the bootstrap script `./bootstrap-centos.sh`


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


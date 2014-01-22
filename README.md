# Katello Deployment

This repository provides methods to easily test and deploy a Katello server.

## Nightly

Currently Katello is only supported on EL6 and available in the Katello nightly repositories. Provided
is a Vagrant setup that will setup and install Katello on a CentOS box. Any base CentOS box and Vagrant 
setup should work but we have been testing and using Vagrant with libvirt. Thus, below are detailed instructions
for setup with libvirt.

1. Ensure you have Vagrant installed, specifically version 1.3+ available from - http://downloads.vagrantup.com/tags/v1.3.5
2. Follow the instructions to install the `vagrant-libvirt` plugin - http://downloads.vagrantup.com/tags/v1.3.5
3. Install the `centos64` box
4. Clone this repository - `git clone https://github.com/Katello/katello-deploy.git`
5. Enter the repository - `cd katello-deploy`
6. Start the installation - `vagrant up`

This will create a libvirt based virtual machine running the Katello server on CentOS.

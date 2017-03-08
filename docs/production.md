# Production Environments

This covers how you can use the tooling provided by Forklift to spin up a production environment for real deployments or evaluation purposes. The tooling can spin up deployments automatically using Vagrant or be used on your virtual or bare metal machines.

 * [Vagrant](#vagrant)
 * [Bring Your Own Box (BYOB)](#byob)


## Vagrant

The Vagrant configuration can currently run pointing at either a Libvirt or Virtualbox setup.

### Using VirtualBox (Windows, OS X)

If you're using Linux, we recommend [Libvirt](#libvirt). The default setup in the Vagrantfile is for VirtualBox. It has been tested against VirtualBox 4.2.18.  To use Install VirtualBox from [the 4.2 downloads
page](https://www.virtualbox.org/wiki/Download_Old_Builds_4_2). Vagrant 1.6.5+ can be downloaded and installed from [Vagrant Downloads](http://www.vagrantup.com/downloads.html)

### Libvirt (Linux)

The Vagrantfile provides default setup and boxes for use with the `vagrant-libvirt` provider. To set this up:

1. Ensure you have Vagrant installed
   * For **libvirt**:
     1. Ensure you have the prerequisites installed `sudo yum install ruby rubygems ruby-devel gcc gcc-c++`
1. Install libvirt. On CentOS/Fedora/RHEL, run `sudo yum install @virtualization libvirt-devel`
1. Install the libvirt plugin for Vagrant (see [vagrant-libvirt page](https://github.com/vagrant-libvirt/vagrant-libvirt) for more information) `vagrant plugin install vagrant-libvirt`
1. Make sure your user is in the `qemu` group. (e.g. `[[ ! "$(groups $(whoami))" =~ "qemu" ]] && sudo usermod -aG qemu $(whoami)`)
1. Set the libvirt environment variable in your `.bashrc` or for your current session - `export VAGRANT_DEFAULT_PROVIDER=libvirt`
1. If you are asked to provide your password for every command, follow [these policykit steps](https://developer.fedoraproject.org/tools/vagrant/vagrant-libvirt.html).

### Vagrant Box Installation

The available versions and types of installs varies as new releases are made and older releases are deprecated. The most accurate way to see the list of available installations is to run the status command:

```
vagrant status
```

This will show a list of boxes by type and OS. For example, at the time of this documentation both Foreman 1.12 and Katello 3.1 had been released. Thus, when doing a status I see, for example:

```
centos6-foreman-nightly   not created (libvirt)
centos7-foreman-nightly   not created (libvirt)
centos6-katello-nightly   not created (libvirt)
centos6-capsule-nightly   not created (libvirt)
centos7-katello-nightly   not created (libvirt)
centos7-capsule-nightly   not created (libvirt)
centos7-foreman-1.12      not created (libvirt)
centos7-katello-3.1       not created (libvirt)
centos7-capsule-3.1       not created (libvirt)
```

This indicates that both Foreman and Katello nightly (our unstable releases) are available as well as production installations on Centos 7 boxes of Foreman 1.12, Katello 3.1 and a Katello Capsule 3.1. To fire up a Katello 3.1:

Start the installation for CentOS 7:

    vagrant up centos7-katello-3.1

This will create a libvirt based virtual machine running the Katello server on CentOS.


## BYOB

This setup assumes you are either deploying on a non-VM environment or you already have a Virtual machine setup. The deployment can be done either locally on the box or via SSH using an [Ansible inventory](http://docs.ansible.com/ansible/intro_inventory.html) script with proper access.

### Remote Deployment

This use case assumes that you are on a box that has SSH access to the target box for installation and that Ansible can properly realize the target host via an inventory script.

1. Ensure Ansible is installed
2. Clone this repository - `git clone https://github.com/theforeman/forklift.git`
3. Enter the repository - `cd forklift`

For a release version in production:

    ansible-playbook -l <target-host> playbooks/katello.yml -e foreman_repositories_version=1.14 -e katello_repositories_version=3.3

For nightly production:

    ansible-playbook -l <target-host> playbooks/katello.yml


After installing a Katello server, you could then spin up a Capsule with the assumption the Katello server can talk to the Capsule and vice versa.

    ansible-playbook -l <target-capsule-host> playbooks/capsule_31.yml

### Local Deployment

1. ssh to target machine **as root**
2. Install Ansible -- `yum install ansible`
3. Clone this repository - `git clone https://github.com/theforeman/forklift.git`
4. Enter the repository - `cd forklift`

For a release version in production:

    ansible-playbook -l localhost playbooks/katello.yml -e foreman_repositories_version=1.14 -e katello_repositories_version=3.3

For nightly production:

    ansible-playbook -l localhost playbooks/katello.yml

<img src="https://raw.githubusercontent.com/theforeman/forklift/master/docs/forklift.png" height="100px">

# Forklift: lifting Foreman into your environment

Forklift provides tools to create Foreman/Katello environments for development, testing and production configurations. Whether you are a developer wanting an environment to write code, or a user wanting to spin up the latest production environment for deployment or evaluation Forklift has you covered.

 * [Using Forklift](#using-forklift)
   - [Adding Custom Boxes](#adding-custom-boxes)
   - [Customize Deployment Settings](#customize-deployment-settings)
   - [Post Provisioning Playbooks & Scripts](#post-install-playbooks)
   - [Customize with Plugins](#plugins)
 * [Production Environments](docs/production.md)
 * [Development Environments](docs/development.md)
 * [Testing Environments](docs/testing.md)
 * [Provisioning environment](docs/provision.md)
 * [Plugins](docs/plugins.md)
 * [Using Forklift as a Library](library.md)
 * [Troubleshooting](docs/troubleshooting.md)

## Using Forklift

### Requirements

* Vagrant - 1.8+ - Both the VirtualBox and Libvirt providers are tested
* Ansible - 2.1+
* [Vagrant Libvirt provider plugin](https://github.com/vagrant-libvirt/vagrant-libvirt) (if using Libvirt)

### Quickstart

This will walk through the simplest path of spinning up a production test environment of a bleeding edge nightly installation assuming Vagrant and Libvirt are installed and configured.

```
git clone https://github.com/theforeman/forklift.git
cd forklift
vagrant up centos7-foreman-nightly
```

The same can be quickly done for a development environment where GITHUB_NICK is your GitHub username:

```
git clone https://github.com/theforeman/forklift.git
cd forklift
cp boxes.yaml.example boxes.yaml
sed -i "s/<REPLACE ME>/GITHUB_NICK/g" boxes.yaml
vagrant up centos7-devel
```

### Poor man's DNS a.k.a /etc/hosts

For the multi-host setup, one of the easiest way of making the name
resolution working with vagrant is using
[vagrant-hostmanager](https://github.com/devopsgroup-io/vagrant-hostmanager). Forklift supports
this plugin by default. The only thing on needs to do is install the vagrant-hostmanager plugin:

```
vagrant plugin install vagrant-hostmanager
```

By default, the boxes are set with `example.com` domain.

### Adding Custom Boxes

Sometimes you want to spin up the same box type (e.g. centos7-devel) from within the forklift directory. While this can be added to the Vagrantfile directly, updates to the forklift repository could wipe out your local changes. To help with this, you can define a custom box re-using the configuration within the Vagrantfile. To do so, create a `boxes.yaml` file. For example, to create a custom box on CentOS 7 with nightly and run the installers reset command:

```
my-nightly-koji:
  box: centos7
  ansible:
    playbook: playbook/katello.yml
    variables:
      katello_repositories_use_koji: True
```

Options:

```
box -- the ':name' one of the defined boxes in the Vagrantfile
bridged -- deploy on Libvirt with a bridged networking configuration, value
           of this parameter should be the interface of the host (e.g. em1)
memory -- set the amount of memory (in megabytes) this box will consume
cpus -- set the number of cpus this box will use
hostname -- hostname to set on the box
networks -- custom networks to use in addition to the management network
disk_size -- specify the size (in gigabytes) of the box's virtual disk. This
             only sets the virtual disk size, so you will still need to
             resize partitions and filesystems manually.
ansible -- updates the Ansible provisioner configuration including the
           playbook to be ran or any variables to set
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

### Customize Deployment Settings

Some settings can be customized for the entirety of the deployment, they are:

 * default_memory: Memory to give boxes by default unless specified by a box
 * default_cpus: Number of CPUs to give boxes by default unless specified by a box
 * sync_type: type of sync to use for transfer to the Vagrant box
 * mount_options: options for the vagrant-cachier plugin

To customize any of these, copy `settings.yaml.example` to `settings.yaml` and add, remove or update the ones you wish to change'

### Post Install Playbooks

Boxes can be further customized by declaring Ansible playbooks to be run during provisioning. One or more playbooks can be specified and will be executed sequentially. An ignored directory can be used to put playbooks into 'user_playbooks' without worrying about adding them during a git commit.

Ansible roles may also be installed directly using the [`ansible-galaxy` command](http://docs.ansible.com/ansible/galaxy.html#the-ansible-galaxy-command-line-tool). These roles will be installed at `playbooks/galaxy_roles` and will be ignored by git. You may also specify roles in a `requirements.yml`, which you can use to install all desired roles with `ansible-galaxy install -r requirements.yml`

```
ansible:
  box: centos7-katello-nightly
  ansible:
    playbook:
      - 'user_playbooks/vim.yml'
      - 'user_playbooks/zsh.yml'
```

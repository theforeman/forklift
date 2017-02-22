<img src="https://raw.githubusercontent.com/theforeman/forklift/master/docs/forklift.png" height="100px">

# Forklift: lifting Foreman into your environment

Forklift provides tools to create Foreman/Katello environments for development, testing and production configurations. Whether you are a developer wanting an environment to write code, or a user wanting to spin up the latest production environment for deployment or evaluation Forklift has you covered.

 * [Using Forklift](#using-forklift)
   - [Adding Custom Boxes](#adding-custom-boxes)
   - [Post Provisioning Playbooks & Scripts](#post-install-playbooks)
   - [Customize with Plugins](#plugins)
 * [Production Environments](docs/production.md)
 * [Development Environments](docs/development.md)
 * [Testing Environments](docs/testing.md)
 * [Provisioning environment](docs/provision.md)
 * [Troubleshooting](docs/troubleshooting.md)

## Using Forklift

### Requirements

* Vagrant - 1.8+ - Both the VirtualBox and Libvirt providers are tested
* Ansible - 2.1+

### Quickstart

This will walk through the simplest path of spinning up a production test environment of a bleeding edge nightly installation assuming Vagrant and Libvirt are installed and configured.

```
git clone https://github.com/theforeman/forklift.git
cd forklift
vagrant up centos7-foreman-nightly
```

The same can be quickly done for a development environment:

```
git clone https://github.com/theforeman/forklift.git
cd forklift
cp boxes.yaml.example boxes.yaml
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
my-nightly-test:
  box: centos7
  installer: '--reset'
```

Options:

```
box -- the ':name' one of the defined boxes in the Vagrantfile
installer -- options that you would like passed to the installer
shell -- customize the shell script run
bridged -- deploy on Libvirt with a bridged networking configuration, value
           of this parameter should be the interface of the host (e.g. em1)
memory -- set the amount of memory (in megabytes) this box will consume
cpus -- set the number of cpus this box will use
hostname -- hostname to set on the box
networks -- custom networks to use in addition to the management network
disk_size -- specify the size (in gigabytes) of the box's virtual disk. This
             only sets the virtual disk size, so you will still need to
             resize partitions and filesystems manually.
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

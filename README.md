<img src="https://raw.githubusercontent.com/theforeman/forklift/master/docs/forklift.png" height="100px">

# Forklift: lifting Foreman into your environment

Forklift provides tools to create Foreman/Katello environments for development, testing and production configurations. Whether you are a developer wanting an environment to write code, or a user wanting to spin up the latest production environment for deployment or evaluation Forklift has you covered.

 * [Using Forklift](#using-forklift)
   - [Requirements](#requirements)
   - [Quickstart](#quickstart)
   - [Poor man's DNS a.k.a /etc/hosts](#poor-mans-dns-aka-etchosts)
   - [Adding Custom Boxes](#adding-custom-boxes)
   - [Customize Deployment Settings](#customize-deployment-settings)
   - [Post Install Playbooks](#post-install-playbooks)
 * [Production Environments](docs/production.md)
 * [Development Environments](docs/development.md)
 * [Testing Environments](docs/testing.md)
 * [Provisioning environment](docs/provision.md)
 * [Plugins](docs/plugins.md)
 * [Using Forklift as a Library](docs/library.md)
 * [Troubleshooting](docs/troubleshooting.md)

## Using Forklift

### Requirements

* Vagrant - 1.8+ - Both the VirtualBox and Libvirt providers are tested
* Ansible - 2.5+
* [Vagrant Libvirt provider plugin](https://github.com/vagrant-libvirt/vagrant-libvirt) (if using Libvirt)
* Virtualization enabled in BIOS

See [Installing Vagrant](docs/vagrant.md) for installation instructions.

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
cp vagrant/boxes.d/99-local.yaml.example vagrant/boxes.d/99-local.yaml
sed -i.bak "s/<REPLACE ME>/GITHUB_NICK/g" vagrant/boxes.d/99-local.yaml
vagrant up centos7-katello-devel
```

You can find more thorough guides in the [docs folder](https://github.com/theforeman/forklift/tree/master/docs).

### Credentials

By default `forklift` deploys Foreman with `admin`/`changeme` as username and password, please change this on production installs (either after the install, or by setting `foreman_installer_admin_password` during the initial deployment).

### Poor man's DNS a.k.a /etc/hosts

For the multi-host setup, one of the easiest way of making the name
resolution working with vagrant is using
[vagrant-hostmanager](https://github.com/devopsgroup-io/vagrant-hostmanager). Forklift supports
this plugin by default. The only thing one needs to do is install the vagrant-hostmanager plugin:

```
vagrant plugin install vagrant-hostmanager
```

By default, the boxes are set with `example.com` domain.

If you're using NetworkManager, [this advanced DNS configuration](https://m0dlx.com/blog/Automatic_DNS_updates_from_libvirt_guests.html)
allows completely automated dns resolution using dnsmasq from host to guest and guest to guest.

You can disable hostmanager in `settings.yaml` by setting `hostmanager_enabled` option.

### Adding Custom Boxes

Sometimes you want to spin up the same box type (e.g. centos7-katello-devel) from within the forklift directory. While this can be added to the Vagrantfile directly, updates to the forklift repository could wipe out your local changes. To help with this, you can define a custom box re-using the configuration within the Vagrantfile. To do so, create a `99-local.yaml` file. For example, to create a custom box on CentOS 7 with nightly and run the installers reset command:

```
my-nightly-koji:
  box: centos7
  ansible:
    playbook: playbooks/katello.yml
    variables:
      katello_repositories_environment: staging
    verbose: vvv
```

Options:

| Option             | Description                                                           |
|:-------------------|:----------------------------------------------------------------------|
| box                |  the ':name' one of the defined boxes in the Vagrantfile |
| bridged            |  deploy on Libvirt with a bridged networking configuration, value of this parameter should be the interface of the host (e.g. em1) |
| memory             |  set the amount of memory (in megabytes) this box will consume |
| cpus               |  set the number of cpus this box will use |
| hostname           |  hostname to set on the box |
| networks           |  custom networks to use in addition to the management network |
| disk_size          |  specify the size (in gigabytes) of the box's virtual disk. This only sets the virtual disk size, so you will still need to resize partitions and filesystems manually. |
| add_disks          |  (libvirt provider only) specify additional libvirt volumes |
| ansible            |  updates the Ansible provisioner configuration including the playbook to be ran or any variables to set |
| libvirt_options    |  sets Libvirt specific options, see [`config.rb` from `vagrant-libvirt`](https://github.com/vagrant-libvirt/vagrant-libvirt/blob/master/lib/vagrant-libvirt/config.rb) for possible options |
| virtualbox_options |  sets VirtualBox specific options |
| rackspace_options  |  sets Rackspace specific options |
| openstack_options  |  sets OpenStack specific options |
| google_options     |  sets Google specific options |
| domain             |  forklift uses short name of your host + 'example.com' as domain name for your boxes. You can use this option to override it. |
| sshfs              |  if you have vagrant-sshfs plugin, you can use sshfs to share folders between your host and guest. See an example below for details. |
| nfs                |  share folders between host and guest.  See an example below for details. |

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

Example with custom libvirt management network:

```
static:
  box: centos7
  hostname: mystatic.box.com
  libvirt_options:
    management_network_address: 172.23.99.0/24
```

Example with openstack provider:  
You will need to install vagrant openstack provider. For more information click [here](https://github.com/ggiamarchi/vagrant-openstack-provider).  
Do not forget to set openstack API credentials.
To use openstack provider as default look [here](https://www.vagrantup.com/docs/providers/default.html).

```
openstack-centos7:
  image_name: 'Centos7'
  username: 'centos'  #root by default
  hostname: 'john-doe'
  openstack_flavor: 'm1.medium'
  sync_type: 'disabled'
```

#### Using SSHFS to share folders

You will need to install [vagrant-sshfs](https://github.com/dustymabe/vagrant-sshfs) plugin. Make sure your host actually has sshfs installed.
Example with sshfs mounting folder from guest to host:

```
with-sshfs:
  box: centos7
  sshfs:
    host_path: '/some/host/path'
    guest_path: '/some/guest/path'
    reverse: True
```

If you want to mount in the opposite direction, just change `reverse` to `False` or remove it entirely.

Additonal options may be specified with using `options`.

```
with-sshfs-options:
  box: centos7
  sshfs:
    host_path: '/some/host/path'
    guest_path: '/some/guest/path'
    options: '-o allow_other'
```

Example with an additional disk (libvirt volume) presented as /dev/vdb in the vm:

```
static:
  box: centos7
  hostname: mystatic.box.com
  add_disks:
    - size: 100GiB
      device: vdb
      type: qcow2
```

#### Using NFS to share folders

An alternative to SSHFS is to share the folders with NFS.  It is slightly more work than SSHFS.  See the [Fedora developer documentation](https://developer.fedoraproject.org/tools/vagrant/vagrant-nfs.html) for information about how to configure an NFS server for Vagrant.

Then create your box:

```
with-nfs:
  box: centos7
  nfs:
    host_path: '/some/host/path'
    guest_path: '/some/guest/path'
```

### Customize Deployment Settings

Some settings can be customized for the entirety of the deployment, they are:

 * memory: Memory to give boxes by default unless specified by a box
 * cpus: Number of CPUs to give boxes by default unless specified by a box
 * scale_memory: Factor to multiply memory of boxes that specify an own value
 * scale_cpus: Factor to multiply CPUs of boxes that specify an own value
 * sync_type: type of sync to use for transfer to the Vagrant box
 * mount_options: options for the vagrant-cachier plugin
 * domain: domain for your hosts, you can override this per-box by configuring your box with a domain directly
 * libvirt_options, virtualbox_options, rackspace_options, openstack_options, google_options: custom options for the various providers

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

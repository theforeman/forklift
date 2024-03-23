<img src="https://raw.githubusercontent.com/theforeman/forklift/master/docs/forklift.png" height="100px">

# Forklift: lifting Foreman into your environment

Forklift provides tools to create Foreman/Katello environments for development, testing and production configurations. Whether you are a developer wanting an environment to write code, or a user wanting to spin up the latest production environment for deployment or evaluation Forklift has you covered.

 * [Using Forklift](#using-forklift)
   - [Requirements](#requirements)
   - [Quickstart](#quickstart)
   - [Foreman Nightly Box](#foreman-nightly-box)
   - [Katello Nightly Box](#katello-nightly-box)
   - [Additional Documentation](#additional-documentation)
   - [Development Environment](#development-environment)
   - [Using Playbooks and Roles Without Vagrant](#using-playbooks-and-roles-without-vagrant)
   - [Credentials](#credentials)
   - [Poor man's DNS a.k.a /etc/hosts](#poor-mans-dns-aka-etchosts)
   - [Adding Custom Boxes](#adding-custom-boxes)
   - [Using SSHFS to share folders](#using-sshfs-to-share-folders)
   - [Using NFS to share folders](#using-nfs-to-share-folders)
   - [Customize Deployment Settings](#customize-deployment-settings)
   - [Customize Available Boxes](#customize-available-boxes)
   - [Post Install Playbooks](#post-install-playbooks)
   - [Using Local Ansible Collection](#using-local-ansible-collection)
 * [Production Environments](https://theforeman.github.io/forklift/production/)
 * [Development Environments](https://theforeman.github.io/forklift/development/)
 * [Stable Boxes](https://theforeman.github.io/forklift/stable_boxes/)
 * [Testing Environments](https://theforeman.github.io/forklift/testing/)
 * [Provisioning environment](https://theforeman.github.io/forklift/provision/)
 * [Plugins](https://theforeman.github.io/forklift/plugins/)
 * [Using Forklift as a Library](https://theforeman.github.io/forklift/library/)
 * [Troubleshooting](https://theforeman.github.io/forklift/troubleshooting/)
 * [Vagrant](https://theforeman.github.io/forklift/vagrant/)
 * [Packer](https://theforeman.github.io/forklift/packer/)

## Using Forklift

### Requirements

* Vagrant - 2.2+ - Both the VirtualBox and Libvirt providers are tested
* Ansible - 2.12+
* [Vagrant Libvirt provider plugin](https://github.com/vagrant-libvirt/vagrant-libvirt) (if using Libvirt)
* Virtualization enabled in BIOS

See [Installing Vagrant](docs/vagrant.md) for installation instructions.

### Quickstart

The quickstart guide covers the basic steps to install Forklift so that you can quickly spin up a production test environment of the latest bleeding edge nightly Foreman or Katello build.

It assumes you have already Vagrant and libvirt installed, as well as the vagrant-libvirt and vagrant-hostmanager plugins. You also need Ansible, although if you don't have it or aren't sure if your version is compatible, you can simply create and activate a Python virtual environment and then `pip install ansible-galaxy`

Start by cloning the Forklift repository:

```sh
git clone https://github.com/theforeman/forklift.git
cd forklift
```

Then install the Ansible collections which are needed by Forklift:

```sh
ansible-galaxy collection install -r requirements.yml
```

When this is complete, simply follow the next section of this README to try out the latest nightly Foreman build using Forklift.

### Foreman Nightly Box

Spin up your box and start using the latest nightly build of Foreman:

```sh
vagrant up centos8-stream-foreman-nightly
```

Access the CLI by first connecting to the box via SSH:

```sh
vagrant ssh centos8-stream-foreman-nightly
```

To access the WebUI, it's helpful to have the vagrant-hostmanager plugin installed, so that your Workstation will automatically be able to resolve the hostname of the box to its IP address.

Then you can simply open your browser and navigate to `https://centos8-stream-foreman-nightly.<HOSTNAME>.example.com` where `<HOSTNAME>` is replaced by the shortname of your workstation. The first time you do this you will need to accept the self-signed certicate.

By default, `forklift` deploys Foreman with `admin`/`changeme` as username and password.

### Katello Nightly Box

Katello nightly boxes are available as well; simply change `centos8-stream-foreman-nightly` to `centos8-stream-katello-nightly` and the steps are otherwise exactly the same as above.

### Additional Documentation

The remainder of this README contains helpful notes on additional topics that are likely to be of interest to users. For the most thorough and complete guides however, please refer to the [docs page](https://theforeman.github.io/forklift).

### Katello Development Environment

If you want a Katello development environment, substitute your GitHub username for `GITHUB_NICK` and run:

```sh
cp vagrant/boxes.d/99-local.yaml{.example,}
sed -i "s/<REPLACE ME>/GITHUB_NICK/g" vagrant/boxes.d/99-local.yaml
```

Bring up the Katello Development Box:

```sh
vagrant up centos8-katello-devel
```

Once the box is running, you can access the shell via SSH and modify the source code in the `~/foreman` and `~/katello` directories. Then start the application to preview your changes:

```sh
cd ~/foreman
bundle exec foreman start
```

Before you can access the WebUI, you must first accept the self-signed certificate on port 3808 by visiting `https://centos8-katello-devel.<HOSTNAME>.example.com:3808` in your browser.

Then, navigate to `https://centos8-katello-devel.<HOSTNAME>.example.com/` to access the WebUI and preview your changes.

As above, `<HOSTNAME>` refers to the shortname of your hypervisor.

There is a much more detailed guide to the development environments in the [full documentation](https://theforeman.github.io/forklift/development/).

See the developer documentation within the Foreman and Katello repositories for instructions on running the test suites, submitting pull requests, etc.

### Using Playbooks and Roles without Vagrant

In case using Vagrant is not desired, ansible playbooks and roles from this repo can be used separately. This is useful if an existing host should be used for the installation, e.g. a beaker machine. In order to deploy the devel environment on host test.example.com, the following needs to be done:

on test.example.com machine, where the dev env should be deployed
```sh
useradd vagrant
echo "vagrant	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers.d/vagrant
```

in forklift checkout
```sh
echo -e "[devel]\ntest.example.com" > inventories/local_inventory
ansible-playbook --private-key=~/.ssh/id_rsa --user root --inventory inventories/local_inventory --extra-vars katello_devel_github_username=katello playbooks/devel.yml
```

In an example above, ansible was instructed to use specific private key (overriding the value from ansible.cfg), root user was set as ssh user and playbook variable was set, so that checkout will be made from katello user.

Other playbooks from playbooks/ directory can be used similarly, though some might need more variables and investigating their parameters is recommended first.

### Credentials

By default `forklift` deploys Foreman with `admin`/`changeme` as username and password, please change this on production installs (either after the install, or by setting `foreman_installer_admin_password` during the initial deployment).

### Poor man's DNS a.k.a /etc/hosts

For the multi-host setup, one of the easiest way of making the name
resolution working with vagrant is using
[vagrant-hostmanager](https://github.com/devopsgroup-io/vagrant-hostmanager). Forklift supports
this plugin by default. The only thing one needs to do is install the vagrant-hostmanager plugin:

```sh
vagrant plugin install vagrant-hostmanager
```

By default, the boxes are set with `example.com` domain.

If you're using NetworkManager, [this advanced DNS configuration](https://m0dlx.com/blog/Automatic_DNS_updates_from_libvirt_guests.html)
allows completely automated dns resolution using dnsmasq from host to guest and guest to guest.

You can disable hostmanager in `vagrant/settings.yaml` by setting `hostmanager_enabled` option.

When using a briged network or with multiple network interfaces, the hostmanager would resolve the internal ip from the ssh-info, you can choose an ip of a particular network interface in `vagrant/settings.yaml` by setting `hostmanager_ip_resolver_device` option with the device name.

```yaml
hostmanager_ip_resolver_device: 'eth1'
```

### Adding Custom Boxes

Sometimes you want to spin up the same box type (e.g. centos8-katello-devel) from within the forklift directory. While this can be added to the Vagrantfile directly, updates to the forklift repository could wipe out your local changes. To help with this, you can define a custom box re-using the configuration within the Vagrantfile. To do so, create a `99-local.yaml` file in vagrant/boxes.d/. For example, to create a custom box on CentOS 8 Stream with nightly and run the installers reset command:

```yaml
my-nightly-staging:
  box: centos8-stream
  ansible:
    playbook: playbooks/katello.yml
    variables:
      katello_repositories_environment: staging
    verbose: vvv
```

Options:

| Option                   | Description                                                           |
|:-------------------------|:----------------------------------------------------------------------|
| box                      |  the ':name' one of the defined boxes in the Vagrantfile |
| bridged                  |  deploy on Libvirt with a bridged networking configuration, value of this parameter should be the interface of the host (e.g. em1) |
| memory                   |  set the amount of memory (in megabytes) this box will consume |
| cpus                     |  set the number of cpus this box will use |
| hostname                 |  hostname to set on the box |
| networks                 |  custom networks to use in addition to the management network |
| disk_size                |  specify the size (in gigabytes) of the box's virtual disk. This only sets the virtual disk size, so you will still need to resize partitions and filesystems manually. |
| add_disks                |  (libvirt provider only) specify additional libvirt volumes |
| ansible                  |  updates the Ansible provisioner configuration including the playbook to be ran or any variables to set |
| libvirt_options          |  sets Libvirt specific options, see [`config.rb` from `vagrant-libvirt`](https://github.com/vagrant-libvirt/vagrant-libvirt/blob/master/lib/vagrant-libvirt/config.rb) for possible options |
| virtualbox_options       |  sets VirtualBox specific options |
| openstack_options        |  sets OpenStack specific options |
| google_options           |  sets Google specific options |
| docker_options           |  sets Docker specific options |
| domain                   |  forklift uses short name of your host + 'example.com' as domain name for your boxes. You can use this option to override it. |
| sshfs                    |  if you have vagrant-sshfs plugin, you can use sshfs to share folders between your host and guest. See an example below for details. |
| nfs                      |  share folders between host and guest.  See an example below for details. |
| autostart                |  set to true to automatically start when using 'vagrant up' |
| primary                  |  set the machine to be the default target of vagrant commands such as 'vagrant ssh' |
| libvirt_qemu_use_session |  Use qemu session instead of system |

Entirely new boxes can be created that do not orginate from a box defined within the Vagrantfile. For example, if you had access to a RHEL Vagrant box:

```yaml
rhel7:
  box_name: rhel7
  shell: 'echo TEST'
  pty: true
  libvirt: http://example.org/vagrant/rhel-7.box
```

Example with custom networking, static IP on custom libvirt network:

```yaml
static:
  box: centos8
  hostname: mystatic.box.com
  networks:
    - type: 'private_network'
      options:
        ip: 192.168.150.3
        libvirt__network_name: lab-private
        libvirt__iface_name: vnet2
```

Example with custom libvirt management network:

```yaml
static:
  box: centos8
  hostname: mystatic.box.com
  libvirt_options:
    management_network_address: 172.23.99.0/24
```

Example with openstack provider:
You will need to install vagrant openstack provider. For more information click [here](https://github.com/ggiamarchi/vagrant-openstack-provider).
Do not forget to set openstack API credentials.
To use openstack provider as default look [here](https://www.vagrantup.com/docs/providers/default.html).

```yaml
openstack-centos8:
  image_name: 'Centos8'
  username: 'centos'  #root by default
  hostname: 'john-doe'
  openstack_flavor: 'm1.medium'
  sync_type: 'disabled'
```

### Using SSHFS to share folders

You will need to install [vagrant-sshfs](https://github.com/dustymabe/vagrant-sshfs) plugin. Make sure your host actually has sshfs installed.
Example with sshfs mounting folder from guest to host:

```yaml
with-sshfs:
  box: centos8
  sshfs:
    host_path: '/some/host/path'
    guest_path: '/some/guest/path'
    reverse: True
```

If you want to mount in the opposite direction, just change `reverse` to `False` or remove it entirely.

Additonal options may be specified with using `options`.

```yaml
with-sshfs-options:
  box: centos8
  sshfs:
    host_path: '/some/host/path'
    guest_path: '/some/guest/path'
    options: '-o allow_other'
```

Example with an additional disk (libvirt volume) presented as /dev/vdb in the vm:

```yaml
static:
  box: centos8
  hostname: mystatic.box.com
  add_disks:
    - size: 100GiB
      device: vdb
      type: qcow2
```

### Using NFS to share folders

An alternative to SSHFS is to share the folders with NFS.  It is slightly more work than SSHFS.  See the [Fedora developer documentation](https://developer.fedoraproject.org/tools/vagrant/vagrant-nfs.html) for information about how to configure an NFS server for Vagrant.

Then create your box:

```yaml
with-nfs:
  box: centos8
  nfs:
    host_path: '/some/host/path'
    guest_path: '/some/guest/path'
```

### Customize Deployment Settings


Some settings can be customized for the entirety of the deployment by copying `vagrant/settings.yaml.example` to `vagrant/settings.yaml` and add, remove or updating:

 * memory: Memory to give boxes by default unless specified by a box
 * cpus: Number of CPUs to give boxes by default unless specified by a box
 * scale_memory: Factor to multiply memory of boxes that specify an own value
 * scale_cpus: Factor to multiply CPUs of boxes that specify an own value
 * sync_type: type of sync to use for transfer to the Vagrant box
 * mount_options: options for the vagrant-cachier plugin
 * domain: domain for your hosts, you can override this per-box by configuring your box with a domain directly
 * libvirt_options, virtualbox_options, openstack_options, google_options: custom options for the various providers

### Customize Available Boxes

The list of available boxes can be customized by setting an exclude list in `vagrant/settings.yaml`. This allows faster `vagrant status` calls as well as reducing the the scope of boxes a user sees to tailor to their use cases. To specify boxes to exclude add the following to `vagrant/settings.yaml`, for example, to remove fips, fedora and any Foreman 1.2X boxes from view:

```yaml
boxes:
  exclude:
    - "katello" # exclude any box containing "katello"
    - "ubuntu1804-foreman-2\\.0" # exclude only the box "ubuntu1804-foreman-2.0". Notice the escaped '.' character to match the specific character instead of any single character
    - "^centos7-fips" # exclude any box that starts with "centos7-fips"
    - "foreman-1\\.(?:[2][0-3])" # exclude any foreman-1.20 to foreman-1.23 version box
```

### Post Install Playbooks

Boxes can be further customized by declaring Ansible playbooks to be run during provisioning. One or more playbooks can be specified and will be executed sequentially. An ignored directory can be used to put playbooks into 'user_playbooks' without worrying about adding them during a git commit.

Ansible roles may also be installed directly using the [`ansible-galaxy` command](http://docs.ansible.com/ansible/galaxy.html#the-ansible-galaxy-command-line-tool). These roles will be installed at `playbooks/galaxy_roles` and will be ignored by git. You may also specify roles in a `requirements.yml`, which you can use to install all desired roles with `ansible-galaxy install -r requirements.yml`

```yaml
ansible:
  box: centos8-stream-katello-nightly
  ansible:
    playbook:
      - 'user_playbooks/vim.yml'
      - 'user_playbooks/zsh.yml'
```

### Using Local Ansible Collection

If needing to use a local copy of an Ansible collection used by Forklift, such as developing updates to theforeman.operations collection, you can temporarily update the `requirements.yml` to point at your local checkout:

```yaml
collections:
  - name: git+file:///home/user/path/to/repo/.git
    type: git
```

Then run `ansible-galaxy` install:

```sh
ansible-galaxy collection install -r requirements.yml --force-with-deps
```

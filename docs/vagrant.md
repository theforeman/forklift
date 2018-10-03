# Installing Vagrant

## Fedora

Assuming you want vagrant with libvirt:

```bash
dnf -y install libvirt-daemon-kvm ansible vagrant-libvirt
systemctl enable --now libvirtd
```
Add your user to the libvirt group to avoid password prompts on running vagrant commands with libvirt provider:

```bash
sudo gpasswd -a ${USER} libvirt
newgrp libvirt
```

## Centos 7

For this you need EPEL and Vagrant RPM

```bash
yum -y install epel-release centos-release-scl
yum -y install libvirt-daemon-kvm ansible https://releases.hashicorp.com/vagrant/2.1.5/vagrant_2.1.5_x86_64.rpm
systemctl enable libvirtd
systemctl start libvirtd
```

Now you need to ensure your user can access vagrant and libvirt:

```bash
usermod --append --groups libvirt `whoami`
```

Install vagrant libvirt plugin:

```bash
sudo yum -y install install libxslt-devel libxml2-devel libvirt-devel libguestfs-tools-c ruby-devel gcc
vagrant plugin install vagrant-libvirt
```

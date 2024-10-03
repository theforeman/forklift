# Installing Vagrant

## Fedora

Assuming you want Vagrant with libvirt:

```bash
dnf -y install libvirt-daemon-kvm vagrant-libvirt
systemctl enable --now libvirtd
systemctl enable --now virtnetworkd
```

Add your user to the libvirt group to avoid password prompts on running vagrant commands with libvirt provider:

```bash
sudo gpasswd -a ${USER} libvirt
newgrp libvirt
```

## CentOS Stream 8 / 9

Enable COPR repositories:

```sh
dnf -y copr enable pvalena/rubygems
dnf -y copr enable pvalena/vagrant
```

Now follow the Fedora instructions.

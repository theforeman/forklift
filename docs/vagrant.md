# Installing Vagrant

## Fedora

Assuming you want vagrant with libvirt:

```bash
dnf -y install libvirt-daemon-kvm ansible vagrant-libvirt
systemctl enable --now libvirtd
```

## Centos 7

For this you need EPEL and SCLo

```bash
yum -y install epel-release centos-release-scl
yum -y install libvirt-daemon-kvm ansible sclo-vagrant1-vagrant-libvirt
systemctl enable libvirtd
systemctl start libvirtd
```

Now you need to run commands in the vagrant SCL. The easiest is to start a new shell:

```bash
scl enable sclo-vagrant1 bash
```

You can also manually load the SCL into your existing bash:

```bash
. /opt/rh/sclo-vagrant1/enable
```

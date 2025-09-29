# Troubleshooting

## Vagrant-libvirt

If you have problems installing the libvirt plugin, be sure to checkout the [troubleshooting section](https://vagrant-libvirt.github.io/vagrant-libvirt/troubleshooting.html) of their README.

## SELinux

If you get this error:

```text
There was an error talking to Libvirt. The error message is shown
below:

Call to virDomainCreateWithFlags failed: Input/output error
```

The easiest thing to do is disable selinux using: `sudo setenforce 0`. Alternatively you can configure libvirt for selinux, see [http://libvirt.org/drvqemu.html#securitysvirt](https://libvirt.org/drvqemu.html#selinux-svirt-confinement)

## NFS

If you get this error:

```text
mount.nfs: rpc.statd is not running but is required for remote locking.
mount.nfs: Either use '-o nolock' to keep locks local, or start statd.
mount.nfs: an incorrect mount option was specified
```

Make sure nfs is installed and running:

```sh
sudo dnf install nfs-utils
sudo service start nfs-server
```

## Low disk space

Your OS may be installed with a large root partition and smaller `/home`
partition. Vagrant will populate `~/.vagrant.d/` with boxes by default; each of
which can be over 2GB in size. This may cause disk space issues on your `/home`
partition.

To store your Vagrant files elsewhere, you can create a directory outside of
`/home` and tell Vagrant about it by setting `VAGRANT_HOME=<path to vagrant dir>`.
You may need to set this in your `.bash_profile` so it persists between
logins.

## Libvirt not reachable

If you get this error:

```text
/usr/share/vagrant/gems/gems/vagrant-libvirt-0.11.2/lib/vagrant-libvirt/driver.rb:207:in `list_all_networks': Call to virConnectListAllNetworks failed: Failed to connect socket to '/var/run/libvirt/virtnetworkd-sock-ro': No such file or directory (Libvirt::RetrieveError)
```

Libvirt might not be fully running make sure by running:

```sh
sudo systemctl start libvirtd
sudo systemctl start virtqemud
sudo systemctl start virtnetworkd
sudo systemctl start virtnetworkd-ro.socket
```

Another possibility could be, that it's necessary to switch libvirt to a modular daemon setup, see [https://libvirt.org/daemons.html#switching-to-modular-daemons](https://libvirt.org/daemons.html#switching-to-modular-daemons)

## Forward DNS

If you get this error in the Run installer section:

```text
stderr: Forward DNS points to 127.0.1.1 which is not configured on this server
```

Make sure that the hostname in `/etc/hosts` does not point to 127.0.1.1 .

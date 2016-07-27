# Troubleshooting

#### vagrant-libvirt

If you have problems installing the libvirt plugin, be sure to checkout the [troubleshooting section](https://github.com/pradels/vagrant-libvirt#possible-problems-with-plugin-installation-on-linux) of their README.

#### selinux

If you get this error:

```
There was an error talking to Libvirt. The error message is shown
below:

Call to virDomainCreateWithFlags failed: Input/output error
```

The easiest thing to do is disable selinux using: `sudo setenforce 0`.  Alternatively you can configure libvirt for selinux, see http://libvirt.org/drvqemu.html#securitysvirt

#### nfs

If you get this error:

```
mount.nfs: rpc.statd is not running but is required for remote locking.
mount.nfs: Either use '-o nolock' to keep locks local, or start statd.
mount.nfs: an incorrect mount option was specified
```

Make sure nfs is installed and running:

```
sudo yum install nfs-utils
sudo service start nfs-server
```

#### low disk space

Your OS may be installed with a large root parition and smaller `/home`
partition. Vagrant will populate `~/.vagrant.d/` with boxes by default; each of
which can be over 2GB in size. This may cause disk space issues on your `/home`
partition.

To store your Vagrant files elsewhere, you can create a directory outside of
`/home` and tell Vagrant about it by setting `VAGRANT_HOME=<path to vagrant
dir>`. You may need to set this in your `.bash_profile` so it persists between
logins.

#### vagrant-libvirt

If you have problems installing the libvirt plugin, be sure to checkout the [troubleshooting section](https://github.com/pradels/vagrant-libvirt#possible-problems-with-plugin-installation-on-linux) of their README.

#### selinux

If you get this error:

```
There was an error talking to Libvirt. The error message is shown
below:

Call to virDomainCreateWithFlags failed: Input/output error
```

The easiest thing to do is disable selinux using: `sudo setenforce 0`.  Alternatively you can configure libvirt for selinux, see http://libvirt.org/drvqemu.html#securitysvirt

#### nfs

If you get this error:

```
mount.nfs: rpc.statd is not running but is required for remote locking.
mount.nfs: Either use '-o nolock' to keep locks local, or start statd.
mount.nfs: an incorrect mount option was specified
```

Make sure nfs is installed and running:

```
sudo yum install nfs-utils
sudo service start nfs-server
```

#### low disk space

Your OS may be installed with a large root parition and smaller `/home`
partition. Vagrant will populate `~/.vagrant.d/` with boxes by default; each of
which can be over 2GB in size. This may cause disk space issues on your `/home`
partition.

To store your Vagrant files elsewhere, you can create a directory outside of
`/home` and tell Vagrant about it by setting `VAGRANT_HOME=<path to vagrant
dir>`. You may need to set this in your `.bash_profile` so it persists between
logins.

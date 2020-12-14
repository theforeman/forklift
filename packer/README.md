## Packer

This directory contains [packer](https://www.packer.io/) templates to create images from provisioned VMs

You can install packer using [the steps in their documentation](http://packer.io/intro/getting-started/install.html). For Fedora and Red Hat flavor distributions, be aware there can be another executable installed named `packer`, so you will have to install the `packer` executable under another name or call it with an absolute path. See [their documentation for more info](http://packer.io/intro/getting-started/install.html#troubleshooting)

*Be aware* that enabling the hashicorp repo will make an updated vagrant rpm available.  If you are using the Fedora-supplied vagrant, disable this repository immediately after installing packer.

### Local usage

From this directory, use `packer build` followed by the json packer template to create an image

For example: `packer build centos7-katello-devel-stable.json`

You can create a box image using the above command and then add that box to vagrant:

```
vagrant box add --name centos7-katello-devel-stable centos7-katello-devel-stable.box
```

Then you can use it in a box definition. For the box built with `centos7-katello-devel-stable.json`, you will need to use the stable hostname.

```
centos7-katello-devel-stable:
  box_name: centos7-katello-devel-stable
  hostname: centos7-katello-devel-stable.example.com
```

You can then `vagrant up centos7-katello-devel-stable`


If you want to completely remove the box, be sure to remove from both vagrant and virsh. This can be helpful if you have built a new packer box image and want to use it.

```
vagrant box remove centos7-katello-devel-stable
sudo virsh vol-delete --pool default centos7-katello-devel-stable_vagrant_box_image_0.img
```

### Creating version specific Katello devel boxes

Versioned Katello devel boxes allow easier patch development on old versions of Katello.  This could be used for creating a fix or updating a vcr cassette for an older release.

To create a version specific dev box, follow the directions above to install packer, then:

```
cd ./forklift/packer
```

and run this comand (replacing 3.18 with the correct version):

```
./scripts/build_stable_dev_box.rb 3.18
```

To test the newly created box:
1.  add the printed box definition to vagrant/boxes.d/99-local.yaml 
2.  run printed 'vagrant box add' command
3.  vagrant up centos7-katello-3.18-stable
4.  Verify that 'rpm -q katello-repos' is correct and the foreman and katello git repos are on the correct branches

### Uploading a versioned box to Vagrant Cloud

The version of Vagrant shipped with Fedora does not support Vagrant Cloud uploads (due to a library licensing issue):

1. Deploy a Centos 7 VM (vagrant up centos7)
2. Install latest vagrant from: https://www.vagrantup.com/docs/installation
3. scp the .box file over to the centos 7 vm
4. Run  'vagrant login' and login with your credentials
5. Ensure you are an owner of the katello organization in vagrant cloud
6. Use the command from the build_stable_dev_box.rb output to publish the box, it will look like:
```
vagrant cloud publish -d "katello-devel 3.18" -s "katello-devel 3.18" katello/katello-devel 3.18.0 libvirt centos7-katello-3.18-stable.box
```

NOTE: YOU WILL GET AN ERROR, BUT THE UPLOAD WILL ACTUALLY WORK.  This only happens during large box uploads to vagrant cloud.  The error will look like:

```
Failed to create box katello/katello-nightly
An error occurred while uploading the file. The error
message, if any, is reproduced below. Please fix this error and try
again.

exit code: 52
Empty reply from server
```

7. Since auto-releasing is somewhat broken, login to the webui (https://app.vagrantup.com/katello/boxes/katello-devel/) and release the version manually

### Using a version specific box

Within your local vagrant boxes file, add:
```
centos7-katello-3.18-stable:
  box_name: katello/katello-devel
  box_version: 3.18.0
```

changing 3.18.0 to the version you desire. Then:

```
vagrant up centos7-katello-3.18-stable
```

### Vagrant cloud usage

The centos7-katello-devel-stable box is [published to Vagrant cloud](https://app.vagrantup.com/katello/boxes/katello-devel) on a nightly basis to ensure an image with the latest changes is available. This box is only published if the Katello install is successful.

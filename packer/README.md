## Packer

This directory contains [packer](https://www.packer.io/) templates to create images from provisioned VMs

You can install packer using [the steps in their documentation](http://packer.io/intro/getting-started/install.html). For Fedora and Red Hat flavor distributions, be aware there can be another executable installed named `packer`, so you will have to install the `packer` executable under another name or call it with an absolute path. See [their documentation for more info](http://packer.io/intro/getting-started/install.html#troubleshooting)

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


### Vagrant cloud usage

The centos7-katello-devel-stable box is [published to Vagrant cloud](https://app.vagrantup.com/katello/boxes/katello-devel) on a nightly basis to ensure an image with the latest changes is available. This box is only published if the Katello install is successful.

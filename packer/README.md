# Packer

This directory contains [Packer](https://www.packer.io) templates to create images from provisioned VMs

You can install packer using [the steps in their documentation](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli). For Enterprise Linux (EL) distributions, be aware there can be another executable installed named `packer`, so you will have to install the `packer` executable under another name or call it with an absolute path. See [their documentation for more info](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli#troubleshooting)

*Be aware* that enabling the hashicorp repo will make an updated vagrant rpm available. If you are using the Fedora-supplied vagrant, disable this repository immediately after installing packer.

## Local usage

From this directory, use `packer build` followed by the json packer template to create an image

To also upload a new box, you will need the client ID and client secret for the stablebox-creator service principal. You can find that in the Access control section of the katello-devel project in the Hashicorp Cloud.

To build a new box, run: `HCP_CLIENT_ID=id HCP_CLIENT_SECRET=secret packer build -var "version=2025.0606.1303" centos9-katello-devel-stable.json`

Increment the version using the current date: `date +%Y.%m%d.%H%M`

The above command  will create a box and then you can add that box to Vagrant locally to test:

```sh
vagrant box add --name centos9-katello-devel-stable centos9-katello-devel-stable.box
```

Then you can use it in a box definition. For the box built with `centos9-katello-devel-stable.json`, you will need to use the stable hostname.

```yaml
centos9-katello-devel-stable:
  box_name: centos9-katello-devel-stable
  hostname: centos9-katello-devel-stable.example.com
```

You can then `vagrant up centos9-katello-devel-stable`

If you want to completely remove the box, be sure to remove from both Vagrant and virsh. This can be helpful if you have built a new packer box image and want to use it.

```sh
vagrant box remove centos9-katello-devel-stable
sudo virsh vol-delete --pool default centos9-katello-devel-stable_vagrant_box_image_0.img
```

## Creating version specific Katello devel boxes

Versioned Katello devel boxes allow easier patch development on old versions of Katello. This could be used for creating a fix or updating a vcr cassette for an older release.

To create a version specific dev box, follow the directions above to install packer, then:

```sh
cd ./forklift/packer
```

and run this comand (replacing 4.13 with the correct version):

```sh
./scripts/build_stable_dev_box.rb 4.13
```

To test the newly created box:

1. add the printed box definition to vagrant/boxes.d/99-local.yaml
2. run printed `vagrant box add` command
3. `vagrant up centos9-stream-katello-4.13-stable`
4. Verify that `rpm -q katello-repos` is correct and the foreman and katello git repos are on the correct branches

## Uploading a versioned box to Vagrant Cloud

The version of Vagrant shipped with Fedora does not support Vagrant Cloud uploads (due to a library licensing issue):

1. Deploy a CentOS Stream 9 VM (`vagrant up centos9`)
2. Install latest vagrant from: [https://developer.hashicorp.com/vagrant/docs/installation](https://developer.hashicorp.com/vagrant/docs/installation)
3. scp the .box file over to the CentOS Stream 9 VM
4. Run `vagrant login` and login with your credentials
5. Ensure you are an owner of the katello organization in Vagrant cloud
6. Use the command from the build_stable_dev_box.rb output to publish the box, it will look like:

```sh
vagrant cloud publish -d "katello-devel 4.13" -s "katello-devel 4.13" katello/katello-devel 4.13.0 libvirt centos9-stream-katello-4.13-stable.box
```

NOTE: YOU WILL GET AN ERROR, BUT THE UPLOAD WILL ACTUALLY WORK.  This only happens during large box uploads to Vagrant cloud.  The error will look like:

```text
Failed to create box katello/katello-nightly
An error occurred while uploading the file. The error
message, if any, is reproduced below. Please fix this error and try
again.

exit code: 52
Empty reply from server
```

7. Since auto-releasing is somewhat broken, login to the webui ([portal.cloud.hashicorp.com katello-devel](https://portal.cloud.hashicorp.com/vagrant/discover/katello/katello-devel)) and release the version manually

## Using a version specific box

Within your local Vagrant boxes file, add:

```yaml
centos9-stream-katello-4.13-stable:
  box_name: katello/katello-devel
  box_version: 4.13.0
```

changing 4.13.0 to the version you desire. Then:

```sh
vagrant up centos9-stream-katello-4.13-stable
```

## Vagrant cloud usage

The centos9-katello-devel-stable box is [published to Vagrant cloud](https://portal.cloud.hashicorp.com/vagrant/discover/katello/katello-devel) on a nightly basis to ensure an image with the latest changes is available. This box is only published if the Katello install is successful.

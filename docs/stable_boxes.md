# Stable Boxes

This section discusses the usage and creation of stable environments.

* [What is a stable box?](#what-is-a-stable-box)
* [How to use](#how-to-use)
* [How are stable boxes created?](how-are-stable-boxes-created)

## What is a stable box?

A stable box is a box that uses a published vagrant image of a successfully installed environment. These boxes usually have names that end with `-stable`, for example `centos7-katello-devel-stable`. 

The boxes are guaranteed to spin up successfully because the installation steps do not happen locally. The boxes are created to make sure an environment is always available even if recent changes are preventing a box from spinning up.

## How to use

#### First spin up
To first time you spin up a stable box, you can perform the usual steps:

1. Copy `vagrant/boxes.d/99-local.yaml.example` to `vagrant/boxes.d/99-local.yaml`. If you already have a `99-local.yaml`, you can copy the entries in `99-local.yaml.example` to your `99-local.yaml`.
2. `vagrant up centos7-katello-devel-stable` to spin up the box (change the box name to the one you want to spin up)

The latest stable box image will be downloaded from Vagrant cloud and used for the environment.

#### Subsequent spin ups

The difference between a stable box and the other boxes is when you want to spin up the box again, you will need to update the underlying box image. The stable box image includes the full installation (for example, a Katello development environment) and is not just the OS image. You can do this with `vagrant box update box-name`

Without updating the box image, Vagrant will use the latest image downloaded locally instead of the latest image published to Vagrant cloud. This workflow is useful when you want an updated "fresh" environment with the latest backend systems, newer deployment changes, and updated packages. You can run the following to destroy your existing box, upgrade the box image to the latest one available, and spin up a new box.

For example with `centos7-katello-devel-stable`:
1. `vagrant destroy centos7-katello-devel-stable`
2. `vagrant box update centos7-katello-devel-stable`
3. `vagrant up centos7-katello-devel-stable`


#### Managing multiple boxes
It is recommended that you destroy your stable box and create a new one because the stable box typically uses a fixed hostname. 

If you would like to create multiple environments by using multiple box entries using the same image, you will need a way to manage having multiple machines with the same hostname. For example, you can keep your `/etc/hosts` file on your hypervisor always pointed to the box you want to use. The previous box's entry in `~/.ssh/known_hosts` will have to be removed as well. 

You don't have to worry about this if you only keep one environment per box image.

#### Cleanup

Vagrant will keep around old box images on your system. You may want to clean up old box images to free up disk space. For example:
```
vagrant box prune katello/katello-devel
```
(use `vagrant box list` to get the box image names):

With libvirt, you will have to remove the corresponding volumes with virsh since vagrant won't remove them. For example:
```
# sudo virsh vol-list --pool default
 Name                                                                      Path
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 katello-VAGRANTSLASH-katello-devel_vagrant_box_image_2019.1018.1354.img   /var/lib/libvirt/images/katello-VAGRANTSLASH-katello-devel_vagrant_box_image_2019.1018.1354.img
 katello-VAGRANTSLASH-katello-devel_vagrant_box_image_2019.1021.1130.img   /var/lib/libvirt/images/katello-VAGRANTSLASH-katello-devel_vagrant_box_image_2019.1021.1130.img

# sudo virsh vol-delete --pool default katello-VAGRANTSLASH-katello-devel_vagrant_box_image_2019.1018.1354.img
Vol katello-VAGRANTSLASH-katello-devel_vagrant_box_image_2019.1018.1354.img deleted
```

#### Some things to keep in mind

At this time any personalizations, such as github remotes, are not configured on the box itself.

## How are stable box images created?

#### The workflow

Box images are created with Vagrant's [Packer tool](https://packer.io). To view development documentation, see [the packer directory's README](../packer/README.md).

Packer will create an image by bootstrapping an operating system from a kickstart file and then run the ansible playbook specified in the Packer template. A cron job (or other automated job) will use Packer to create this box on a set schedule. If the box succeeds in its installation, it is published to Vagrant cloud. This ensures that only successfully installed boxes are used for the stable image.

#### Example publishing workflow

For example, here is the workflow for `centos7-katello-devel-stable`:

1. A cron job or scheduled automation builds the box image with Packer using the `packer/centos7-katello-devel-stable.json` template.
2. This bootstraps CentOS 7 from an ISO and kickstart file and runs our katello devel environment playbook, creating an image.
3. This image is published to [Vagrant cloud](https://app.vagrantup.com/katello/boxes/katello-devel) using the date as a version to ensure it's the latest version. The image is only published if the katello development environment playbook has successfully ran.

Then locally:

1. A forklift user uses the box definition with `katello/katello-devel` as the base image, most likely the copied `centos7-katello-devel-stable` box definition.
2. On `vagrant up centos7-katello-devel-stable`, the most recent box image is downloaded from Vagrant clould and the box is created.

#### Key differences

The end result of both the stable box and its traditional counterpart should be the same.

Any differences between the two could come from:
- The stable box uses a ISO and kickstart file instead of a base OS vagrant box image, which could lead to some small differences on the OS and system level.
- The stable boxes use a fixed hostname since the Foreman/Katello installation is not happening on a user's system and therefore the hostname is not customized to the user's hypervisor.
- A stable box includes the most recent changes at the time of its publishing, a change could be introduced after it was published (a foreman-installer change, for example). The traditional box would have this change and the stable box would not until it is re-published.
  - We try to publish stable box images frequently for this reason.
  
A good way to think about a stable box is it's the same as if you spun up its traditional counterpart at the exact time the stable box image was published to Vagrant cloud.

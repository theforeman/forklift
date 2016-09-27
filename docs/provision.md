# Katello provisioning setup

A role is included which will configure an all-on-one provisioning environment
with Katello. It uses nested libvirt to make your virtual machine a hypervisor
capable of running it's own VM's.  It also sets up a private NAT network on the
host.

## How to configure

1. Enable nested virt on your phyiscal box.  See http://www.rdoxenham.com/?p=275
comments for more details.  Essentially, add this line to kvm-intel.conf and
reboot:

        echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf

2. Build a box

    - Option 1: Use the `centos7-provisioning-nightly` box.

    - Option 2: Use an existing katello box (e.g. centos7-katello-p4-nightly) and run the provisioning playbook (it takes a while, as it syncs (on-demand) centos7, puppet 4).   ***Note*: If you are using puppet 4, you need to increase the ram on the box, to something like 8096 otherwise candlepin crashes with OOM.**
        `ansible-playbook -l centos7-katello-p4-nightly playbooks/katello_provisioning.yml`

4. Login and create a compute profile, because this isn't possible with hammer or the API.

   - Click Infrastructure / Compute Resources
   - Click "libvirt"
   - Click Compute profiles
   - Click 2-Medium
        - increse ram to 1024MB (required for centos 7)
        - change network type to NAT, network name = provision
   - Click Submit

5.  Configure Activation Key

  - Content/ Activation Keys
  - Assign all available subscriptions to the activation key

6. Configure / Host groups

    - Edit Forklift CentOS 7
    - Set Compute profile to be "2-Medium"
    - Assign the `CentOS 7` activation key to the host group

7. You're good to go! Let's provision a box!

     - Click Hosts/ New Host
     - Fill in:
                - org, location, host group
                - deploy on = libvirt

     DONE! Click submit :tada:

7. If you want to view the console while it boots, make sure to trust the CA certificate in your browser, it's hosted at https://centos7-katello-nightly.example.com/pub/katello-server-ca.crt, and you'll need to make sure you're accessing the katello via it's proper hostname (add an entry to /etc/hosts)

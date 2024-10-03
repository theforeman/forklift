# Katello provisioning setup

A role is included which will configure an all-on-one provisioning environment
with Katello. It uses nested libvirt to make your virtual machine a hypervisor
capable of running it's own VM's.  It also sets up a private NAT network on the
host.

## How to configure

1. If necessary, enable nested virt on your phyiscal box (see in [Checking if nested virtualization is supported](https://docs.fedoraproject.org/en-US/quick-docs/using-nested-virtualization-in-kvm)). Essentially, add this line to kvm-intel.conf and reboot:

    ```
    echo "options kvm-intel nested=1" | sudo tee /etc/modprobe.d/kvm-intel.conf
    ```

2. Build a box
    * Option 1: Use the `centos9-provision-nightly` box.

    * Option 2: Use an existing katello box (e.g. centos9-stream-katello-nightly) and run the provisioning playbook (it takes a while, as it syncs (on-demand) centos9, puppet 7).  
    NOTE: If you are using puppet 7 or higher, you need to increase the ram on the box, to something like 8096 otherwise candlepin crashes with OOM.

        ```
        ansible-playbook -l centos9-stream-katello-nightly playbooks/katello_provisioning.yml
        ```

3. Login and create a compute profile, because this isn't possible with hammer or the API.
    * Click Infrastructure / Compute Resources
    * Click "libvirt"
    * Click Compute profiles
    * Click 2-Medium
        * increse ram to 2048MB (required for centos 9)
        * change network type to NAT, network name = provision
    * Click Submit
4. Configure Activation Key
    * Content / Activation Keys
    * Assign all available subscriptions to the activation key
5. Configure / Host groups
    * Edit Forklift CentOS 9
    * Set Compute profile to be "2-Medium"
    * Assign the `CentOS 9` activation key to the host group
6. You're good to go! Let's provision a box!
    * Click Hosts / New Host
    * Fill in:
        * org, location, host group
        * deploy on = libvirt

    DONE! Click submit :tada:

7. If you want to view the console while it boots, make sure to trust the CA certificate in your browser, it's hosted at [https://centos9-stream-katello-nightly.example.com/pub/katello-server-ca.crt](https://centos9-stream-katello-nightly.example.com/pub/katello-server-ca.crt), and you'll need to make sure you're accessing the katello via it's proper hostname (add an entry to /etc/hosts).

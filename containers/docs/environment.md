# Environment

After deployment, the UI can be accessed at `https://foreman-443-foreman.$(minishift ip).nip.io/` when using minishift. If you are using an existing cluster, use `oc get routes` to find the hostname.

## Registering a Client

The workflow to register an RHSM client differs slightly from a standard installation.

```
wget --no-check-certificate https://<hostname>/pub/katello-rhsm-consumer-1.0-1.noarch.rpm
yum install katello-rhsm-consumer-1.0-1.noarch.rpm
FOREMAN_HOSTNAME=<hostname> /usr/bin/katello-rhsm-consumer
```

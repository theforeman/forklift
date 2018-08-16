# Upgrades From Traditional to Container Deployment

This document aims to capture proposed upgrade scenarios for traditional deployments migrating services and data to a containerized deployment model.

 * [Requirements](#upgrade-requirements)
 * [Data Sources](#data-sources)
 * [Strategies](#strategies)

### Upgrade Requirements

The intent is to ensure that users can move from a traditional to containerized deployment with as little impact to their infrastructure as possible and without leaving behind any users to continue to grow the community. In order to facilitate this, upgrades should operate with the following in mind:

 * All data must transition to be usable by new deployment model
 * Remote datastores and databases should continue to work
 * Clients must continue to work against new deployment

##### Open Questions on Requirements

 * Should migration be limited to the same code version running in both deployments?
For example, should we only allow migration from Foreman traditional to Foreman containers
 * What is the parallel path support time frame? In other words, for how long do we have two deployment models and support them in parallel?
 * This affects how long we give users a chance to migrate to the new platform and how much support cost we incur maintaining both

##### Data Sources

Current deployments rely on multiple databases and file data stores for storage of critical information required to operate. These databases and data stores can range from 10s of GB to multiple TBs of data. These are the data stores that must be migrated with size ranges based on known user deployments:

 * Postgres database
  - /var/lib/pgsql/data
  - 1 GB - 25 GB
 * MongoDB database
  - /var/lib/mongodb
  - 5 GB - 300 GB
 * Pulp content store
  - /var/lib/pulp
  - /etc/puppetlabs/code/environments
  - 100 MB - 3 TB
 * Certificates for client communication
  - /etc/pki/katello
  - /usr/share/foreman
  - /etc/foreman-proxy
  - ….
  - < 30 MB
 * SCAP reports
  - /var/lib/foreman-proxy/openscap/
  - 1 - 100 MB

### Strategy

The aim is to take the existing server, expand the memory and CPU footprint to support running K8s on it and migrate services from the host to the containerized version of them. Databases and data stores would continue to live on the host and be connected to services inside K8s or volume mounted where necessary. This strategy allows for the transition of services to containers over time based on project and stability as well as bringing online new services in a container native way. A proxy will be required to route services properly to the K8s based services to provide a seamless hostname as we do today to keep clients and infrastructure working as expected. Early candidates for transition:

 * Foreman
 * Dynflow
 * Pulp 2 & 3
 * Candlepin
 * Stateless services

**Pros**

 * Single host deployment, re-uses existing host
 * Allows slow transition of services
 * All stakeholders can more slowly learn and become comfortable with containers
 * New containerized services can be brought online in a container native way
 * Keeps qpid-router running on host which is not currently solved in K8s

**Cons**

 * Potentially requires a host with more RAM and CPU for users
 * Installing K8s on existing host with other services may not be optimal
 * Will require some proxying to ensure services route to the correct place
 * Will need hybrid upgrade and management tooling, likely wrapping existing installer in Ansible

Example Architecture

![Upgrade Strategy 3](./upgrade_strategy_3.png)

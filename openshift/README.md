# Foreman on OpenShift

## NOTE: THIS IS NOT FOR PRODUCTION (yet)

The following is currently a proof of concept for running Foreman, Katello and the backend systems on OpenShift. This currently uses repository forks with patches, as well as security and data persistence compromises to achieve this. There is a list of to-dos at the bottom of this README that outlines next steps to get this closer to both production and developer readiness.

Caveats:

 * running without any SSL
 * using forks of some repositories due to needed functionality for this to work

Table of Contents

 * [Setup and Install](./docs/setup-and-install.md)
 * [Architecture](./docs/architecture.md)
 * [Issues to be Addressed](#issues)

For diagrams outlining the architecture, please see the diagrams in the `docs/` folder.

## Issues

This is a list of TODOs that were obvious to this point for what needs to be solved. By no means is this the full and final list.

 * Remove depends_on in favor of container code to wait on services to come up for robustness in all environments
 * find better solution for proxy registration in both environments
 * add pulp_streamer and squid services
 * solve Pulp journald logging (and remove use of Stream handler hack on my fork)
 * move away from basic auth for Pulp to cert auth
 * create shared container for foreman-tasks and foreman
 * add qpid connection to Candlepin
 * add qpid connection to Katello
 * add goferd service for clients
 * add qdrouterd for client connections
 * add Katello client certificate RPM for subscription-manager registration
 * run public facing routes on SSL
 * connect internal services via SSL using secrets
 * concurrency issue with a proxy being spun up at the same time as the server and needing to register
 * run bats inside OpenShift
 * add rsync workflow to develop Foreman locally
 * add Qpid bind to specific events
 * use separate database for Candlepin?

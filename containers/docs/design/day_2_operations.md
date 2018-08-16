# Day 2 Operations

This document aims to capture how Day 2 operations such as backup, restore, upgrades are handled in a containerized deployment model.

 * [Upgrades](#upgrades)
 * [Logging](#logging)
 * [Monitoring](#monitoring)
 * [Backup and Restore](#backup-and-restore)
 * [Tracing](#tracing)

### Container Upgrades

With the use of a Kubernetes operator to manage the deployment and running state of the Foreman instance and underlying services, upgrades would be handled through [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager)(OLM). The OLM project aims to provide packaging of an operator, versioning and upgrades of the operator itself and resources managed by the operator. This will allow managed upgrades when advanced upgrade strategies are required such as multi-container orchestration.

### Logging

Use of an external or internally deployed Elastic-Fluentd-Kibana (EFK) stack to collect container logs and any services running on the host in a hybrid deployment. Fluentd can be deployed as a sidecar container to services to collect and forward logs or on the host to collect logs.

### Monitoring

Use of external or internally deployed Prometheus to collect monitoring metrics from the Kubernetes environment and host as well as individual container metrics.

### Backup and Restore

Initially foreman-maintain would continue to be the target for running management operations against a deployment. This includes backup and restore. Over time, backup and restore can be moved into their own Kubernetes operators to perform operations within the cluster. This may involve net-new tooling or running foreman-maintain within Kubernetes to provide the operational mechanics of performing the backup and restore operations.

### Tracing

Tracing aids in debugging by providing a view of requests through the set of services. This can be achieved by use of the [Istio](https://istio.io/) project to provide among other things tracing, connection reliability and routing.

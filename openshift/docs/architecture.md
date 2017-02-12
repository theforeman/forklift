# Architecture

This document outlines the architecture design for the deployment of the Foreman application using containers on Openshift.

## Service Breakdown

This section outlines each of the services contained within the architecture diagram. In nearly all cases each service has its own dedicated Kubernetes pod and requires some form of communication to one or more other services. The services will be listed in an a layering order starting with the bottom most data layer working up to the user facing application layer.

### Databases

    Name: Postgres
    Description: SQL database
    Used By:
      - Foreman
      - Foreman Tasks/Dynflow
      - Candlepin
    Volumes: Requires a single persistent volume for storage of the database data

    Name: MongoDB
    Description: NoSQL database
    Used By:
      - Pulp
      - Pulp Worker
    Volumes: Requires a single persistent volume for storage of Pulp database

### Backend Services

There are two major backend services used by Foreman: Pulp and Candlepin. This section breaks these services down individually but keeping in mind that each service description is still a pod unto itself.

#### Pulp

Pulp is a backend service that provides content mirroring services for the Foreman application.

    Name: Pulp API Server
    Description: Main server of the Pulp application, provides a REST API and dispatches work to async workers via messaging
    Used By:
      - Foreman
    Requires:
      - Qpid
      - MongoDB
    Volumes: Requires persistent storage for holding Pulp content such as RPMs, Puppet modules, etc.

    Name: Pulp Worker
    Description: Processes asynchornous jobs coming from the Pulp server. Can scale from 1-N depending on workload.
    Used By:
      - Pulp
    Requires:
      - Qpid
      - MongoDB
    Volumes: Requires the same persistent volume storage attached to the Pulp API server

    Name: Pulp Resource Manager
    Description: Manages queuing of Pulp asynchronous tasks onto workers; typically only one of these is needed.
    Used By:
      - Pulp
    Requires:
      - Qpid

    Name: Pulp Celery Beat
    Description: Monitors and manages the state of Pulp workers. Typically only one of these is needed.
    Used By:
      - Pulp
    Requires:
      - Qpid

#### Candlepin

Candlepin is a backend service that provides entitlement management for content and hosts.

    Name: Candlepin
    Description: Application running inside Tomcat providing a REST API and publishing event information to a message bus.
    Used By:
      - Foreman
    Requires:
      - Postgres
      - Qpid

#### Qpid

Qpid is a backend message queue and bus that is used by multiple services to either distribute work or to publish asynchronous information for consumption by other services.

    Name: Qpid
    Description: Asynchronous message broker
    Used By:
      - Pulp
      - Pulp Worker
      - Pulp Resource Manager
      - Pulp Celery Beat
      - Candlepin
      - Foreman

### Third Party Services

There are some services that are considered third party in that they are not a required backend service but can be externally provided instance that is managed or spun up within the deployment to manage the intended target application. The best example of this is using Foreman to manage Puppet. Foreman can manage an external or pre-existing Puppet server or a brand new one can be spun up as part of the deployment to provide management of puppet agents and content.

    Name: Puppet Server
    Description: Provides a server for collecting reports and providing content updates to Puppet managed hosts
    Used By:
      - Foreman
      - Foreman Proxy
    Volumes: Uses a single persistent volume for storage of puppet environments. This volume can be shared with Pulp workers if Pulp is managing and providing Puppet content.

### Main Application

    Name: Foreman
    Description: User facing application server that provides a UI and API for users and host system to get information from and perform actions to.
    Used By:
    Requires:
      - Pulp
      - Candlepin
      - Qpid
      - Postgres

    Name: Foreman Tasks / Dynflow
    Description: Asynchronous task processor and orchestration engine
    Used By:
      - Foreman
    Requires:
      - Postgres

    Name: Foreman Proxy
    Description: Web server providing REST API for managing third party services as a single API endpoint
    Used By:
      - Foreman
    Requires:
      - Foreman
    Optional:
      - Puppet Server

### Persistent Volume Breakdown

There are high number of persistent volumes required by the entirety of the deployment. This section breaks down what each of these volumes are and which services require them.

    Name: Postgres Data
    Description: Used by Postgres to store database data
    Used By:
      - Foreman
      - Candlepin

    Name: MongoDB Data
    Description: Used by MongoDB to store database data
    Used By:
      - Pulp
      - Pulp Worker

    Name: Pulp RPM Content
    Description: Used by Pulp to store RPM content on disk
    Used By:
      - Pulp
      - Pulp Worker

    Name: Puppet Content
    Description: Stores puppet modules imported to Pulp and used by Puppet server to send out to hosts managed by Puppet
    Used By:
      - Pulp
      - Pulp Worker
      - Puppet Server

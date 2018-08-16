# Containerizing the Foreman Ecosystem

This RFC serves as the entry point to a series of RFCs related to the containerization and next generation platform for the Foreman ecosystem. This document aims to capture all design and discussion relating to every aspect of containerization including architecture, upgrades, plugins, CI/CD, etc. The RFC is broken out into multiple documents given the breadth of each. This should provide focus on a given topic and allow more focused discussion.

**Breakouts**

 * [Project Management and Community](./project_management.md)
 * [Container Images](./container_images.md)
 * [Deployment and Architecture](./deployment.md)
 * [Upgrades](./upgrades.md)
 * [Plugins](./plugins.md)
 * [Day 2 Operations](./day_2_operations.md)
 * [Developers](./developers.md)


### Executive Summary

Also read through [Project Management and Community](./project_management.md) for more on developer and user community consideration and impact.

**Objective**: Provide a scalable and highly available platform for running a set of management services.

**Goals**

 * Be agile in delivery of functionality
 * Evolve into a platform that can support the changing needs of the community
 * Increase developer awareness of production deployment
 * Increase ability of developers to deliver functionality with more agility
 * Reduce build-measure-learn loop

**Pros**

 * Development environment moves closer to production through image reuse
 * Developers learn containers Kubernetes (K8s)
 * Container native scaling, high availability, orchestration
 * Plugins can evolve into services easier and deliver functionality more asynchronously
 * There is a large community around Containers, K8s, etc.
 * Scaling means adding more CPU/RAM or an additional cluster node
 * Can reduce deployment pain by decreasing OS and stack support matrix
 * Reduction of packaging burden by using native packaging to build container images

**Cons**

 * Developers have to learn containers, K8s
 * Uncertainty of how services will behave in a containerized deployment
 * Some Smart Proxy functionality may still require non-container or non-container-orchestration world requiring a hybrid approach
 * Hybrid approach may require more knowledge straddling host and container deployment of services
 * Stable Foreman base of installation, supportability exist already
 * Community must become container and K8s aware
 * Running K8s may require more CPU/RAM increasing minimum requirements for users for base installs

##### Devil’s Advocate

A non-containerized approach means continuing to deploy services on a bare metal or VM host and managing through systemd. Scale out for these services involves native scaling of the application itself (e.g. increasing threads) or multiple application nodes with a load balancer in front. The host machine either has to have increased CPU/RAM or work has to be done towards a multi-node setup whereby one or more services can be either moved off to a new box or new instances of the service spun up. This is effectively scale out via additional bare metal or VMs. This scale out will require additional tooling to effectively manage and orchestrate. Additionally, services such as proxies or load balancers will need to be added to deployments.

** Pros **

 * Build on the base of existing stable Foreman gradually
 * Current installer can mostly be re-used with orchestration from Ansible wrapping it
 * Less knowledge overhead for Developer and Users as there are no containers involved
 * No investment in new resources and technology to support containers
 * Existing investment in support, debugging, tooling, documentation

** Cons **

 * Requires adding in new scale services such as proxies and load balancers
 * CPU/RAM requirements go up on the host, or multiple nodes are required for development and testing
 * Foreman developers are less inclined to learn containers
 * Bringing container native services into Foreman may require more work to package and run natively
 * Bringing in future install bases may require building modules and SCL

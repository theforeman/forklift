# Plugin/Service Design

This document aims to capture the strategy for existing plugins, and next generation plugins designed to act as services. This will be dependent on and drive the overall architecture.

 * Existing Plugin Design
 * Plugin Design Proposal
 * Plugins as Services Design Proposal

### Existing Plugin Design

 * Developed as Rails engines in Ruby
 * Declare plugin properties through plugin API
 * Add API and UI through gem packaging enabled through bundler
 * Bring along database tables and migrations
 * Add attributes to existing core tables tightly coupling
 * Add code to existing models, controller through Ruby-isms and not defined API
  - Include
  - Extend
 * Addition of plugin requires server process restart

### Plugin Design Proposal

This design is centered around allowing existing plugins to undergo little to no change but still be delivered independently of a base image.

#### Design

 * Core image:
   - Contains only what is needed to run vanilla Foreman
 * Plugin Images:
   - Contain plugin code and dependencies
   - Contain bundler.d file to activate plugin
   - Contain any settings or configuration files

#### Deployment

 * Core image is deployed initially and considered running as a service
 * Plugins are added by deploying their images as either a deployment or job or added as a sidecar container
 * Plugin deployments mount a shared volume with core container
 * Copy plugin code, dependencies, bundler.d and settings file to shared volume
 * End of deployment triggers restart of core container deployment

**Pros**

 * Foreman core container can focus on vanilla Foreman
 * Plugins require little change to continue working
 * Plugins can be delivered asynchronously to Foreman

**Cons**

 * Requires shared storage for runtime code
 * Plugins cannot be removed or turned off easily
 * Addition of plugins require server restart

**Open Questions**

 * How to disable a plugin

### Plugins as Services Design Proposal

This design proposal aims to move plugins towards a service oriented design focusing on independent plugin release, and core service(s) with the ability to scale plugins independently.

#### Design

 * Core Image:
  - Contain what is needed to run Foreman core service
 * Plugin image
  - Contains all plugin code, settings, and dependencies
  - Runs a stand-alone webserver
  - Provides API and UI
  - Apache frontend handles routing to services

**Pros**

 * Plugins can be added, removed and scaled independently
 * Plugins can have independent release cycles
 * Plugins could be written in any language potentially
 * Core image focuses on core service(s) and stable API
 * Core image can rev independently
 * Easy for plugins to bring along dependent backend services

**Cons**

 * Requires redesign of plugins
 * Plugins must provide full stack for webserver
 * Using existing APIs, communication is JSON over HTTP(s) protocol which potentially has speed problems at scale (see open questions about RPC over HTTP2)

**Open Questions**

 * How to handle UI?
 * Cohesive UI with plugins providing UI
 * Use common framework for header and navigation
 * Use state service (or make part of core) to mark things like active page
 * Master service UI page that routes to individual independent UIs
 * Should Istio be used for service routing?
 * Investigate gRPC for inter-service communication
 * HTTP2 can speed up HTTP calls -- changes needed?
 * Should plugins be allowed to modify core database tables?
 * Migration, evolution path?
 * Should we encourage the use of standardized webserver stacks and provide templates or library code to enable service creation?

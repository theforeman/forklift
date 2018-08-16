# Project Management

 * [Project Name](#project-name)
 * [Change Management](#change-management)
 * [Developer Community](#developer-community)
 * [User Community](#user-community)
 * [Partner Communities](#partner-communities)

### Project Name

The current project lives under the umbrella of the Forklift project. Given the scope of the containerized effort, this should likely be moved within it's own project structure. Proposed new names:

 * Forklift 2.0 (same name and project, fresh vision)
 * Excavator
 * Pylon
 * Mast (https://www.eureka-forklifts.com.au/info/container-masts/)

### Change Management

 * Use Github issues on either Forklift or yet to be named new project
 * Changes should follow standard PR + maintainer approval workflow
 * Changes should attempt to add tests for new functionality

### Developer Community

Developers should be encouraged and able to develop using a containerized deployment that models the production deployment of containers as closely as possible. Enabling developers to use a container deployment in day to day operations provides value by:

 * Developers become more comfortable with container deployment
 * Developers are more likely to contribute fixes back the containerized deployment
 * Developers would developing in a nearly production environment reducing environmental bugs

### User community

Users are the main target for use of a containerized deployment through testing and use in their production environments. The change to containers presents not only a physical shift in user infrastructure but more so a mental shift in how to think about a new deployment model and net new knowledge in how to operate the application managing their infrastructure. In some cases users will be looking to deploy the new containerized platform in their local or company production environments. In a lot of cases, users will need to upgrade their traditional deployments to a containerized version. Further, upstream users have a variety of deployments from vanilla core Foreman to Foreman with some combination of simple plugins to Foreman with complex plugins.

Concerns that need to be accounted for with user community:

 * User education on container orchestration technology, concerns for deploying and how to manage it
 * Upgrades of existing deployments to new platform

One of the major concerns with the transition to a containerized deployment for the user community is gaining their support that this new direction makes sense as the next evolution of Foreman. To enable this, the community needs to be shown through clear documentation and communication the value for individual users and the community as whole (users and developers). Further, users should be presented with tooling that aides in the setup, migration and maintenance of this new deployment model. Users will need tools to aide them in building a container or combination of services for their needs (e.g. provides their set of plugins), deployment tooling, handling upgrades and configuring the environment to their requirements.

User value communication:

 * Smaller, faster updates for bug fixes and features
 * Smaller, lightweight plugin/services for customized infrastructure management per user need
 * More robust releases via development on production like environments
 * Customizable scaling based on user workloads

In order to communicate the shift in direction, the value add and keep a dialog with the user community, the following activities should be undertaken:

 * Regular contributions to community demo showing current state of container work
 * Regular communication of container development plan and activities to the mailing list
 * An upstream repository of documentation related to containers, design, and how to contribute
 * Engage early adopters to test container deployments in their infrastructure

### Partner Communities

The Formean project and plugins integrate with a variety of services and in some cases use them as backends for off loading critical workloads. The Katello plugin in particular makes use of and collaborates heavily with Pulp, Candlepin and Qpid projects. In the traditional, puppetized deployment of Foreman, puppet modules were developed to configure the backend services within the Foreman community without collaboration with these partner communities. Each project continued to handle RPM builds but throughout the history Katello has carried the projects RPMs in it’s repositories at one time or another.

As the containerization project progresses, artifacts will be created that would provide benefit for our partner communities. These are artifacts such as container images, deployment configuration onto an orchestration engine, Helm charts or operators, etc. In other words, this effort will produce functionality necessary to run and operate a partner communities technology as a stand alone deployment. This provides value to the partner community by giving users a way to deploy a given project via containers and onto an orchestration system. This potentially provides opportunities for partner communities to upgrade to the Foreman community by bringing Foreman services online with their existing services.

The project should strive to engage our partner communities for engagement in and consumption of containerized artifacts. This can can come in the following formats:

 * Make partner communities aware of our efforts through mailing list posts and demos
 * Encourage contribution from partner communities through efforts to ensure partner services run stand-alone
 * Engage developers from partner communities to take ownership of parts relating to their projects
 * Work cross-functionally with members of partner communities during all stages of the SDLC

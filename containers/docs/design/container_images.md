# Container Images

The basic unit of a containerized deployment are the static images that are used to run services. Similar to artifacts like source archives, RPMs or Debian packages the images need to be built for myriad concerns such as nightlies and in conjunction with Foreman releases. The images must be defined, built and tested. This document covers the strategy for how images are defined, built for different release targets and tested to ensure a stable deployment.

 * [Defining Images](#defining-images)
 * [Build Strategy](#build-strategy)
 * [Deployment Strategy](#deployment-strategy)

### Defining images

Container images for the Foreman ecosystem will live in an `images` directory where each image is represented by a directory by the same name as the the image. Each image will contain a `Dockerfile` that defines the base image and all instructions required to build the image. Assets that need to be copied into the container will live in a `container-assets` directory to identify them. For example, an image for Foreman would look like the following:

```
images/foreman
├── container-assets
│   ├── database.yml
│   ├── entrypoint.sh
│   ├── settings.yaml
└── Dockerfile
```

The various images that will be required to support Foreman deployments will have some inter-dependency between them. Keeping them all co-located should make re-builds easier when orchestration is required.

### Build Strategy

The build strategy reflects how changes to container images are handled to ensure that images build properly, and deployments continue to work.

**On PRs to change `images/` directory**

 * Run a test build with docker or buildah
 * Modify any references to the image(s) in the deployment code
 * Run a deployment
 * Run smoke tests
 * If tests pass, mark PR as green

**Nightly builds based on source changes**

 * When a PR is merged to a target source repository (e.g. Foreman core) initiate a rebuild of any images tied to that repository
   * For example, when code merged to Foreman core, build Foreman image and then build Dynflow image
 * Modify any references to the image(s) in the deployment code
 * Run a deployment
 * Run smoke tests
 * If tests pass, promote new image to `latest` tag on quay.io

### Container Build Mechanism

As the container world has evolved, different methods have been built to build container images. There are methods to build on platforms, to build locally with different tools and push to external registeries. A major consideration is how dependent images are handled given this involves build orchestration in a prescribed order. There are two options for build mechanisms:

**Option A: Build Local, Push Remote**

 * Use docker or buildah to build images locally and push them to quay.io
 * Requires storage of quay.io robot credentials

**Option B: Build Remote**

 * Orchestrate hitting quay.io API to perform builds on quay
 * Requires storage of quay.io organization “application” credentials to interact with API
 * Orchestrate tooling with Ansible
 * Express container build relationships through configuration
 * Use Ansible to build out tools that are run locally or in CI/CD for building images

### Image testing

The use of base containers means that container builds must be orchestrated in a given order to ensure all child containers are running the same stack.
Changes just to the Dockerfiles or container-assets do not completely represent when an image should change. Both the build artifacts and source repository changes need to be considered to determine rebuild. Further, image or source changes affect not only whether an image will build but the runtime behavior of the image. Both aspects should be tested whenever a change is made to ensure stability.

The general strategy for any image change is to kick off a CI job that builds the container (and children) when a change is made to the related source or image for the container, perform a deployment and verify with a set of smoke tests.

Example:

 * A pull request (PR) is merged to Foreman’s develop branch
 * The merge triggers a CI job that re-builds the Foreman container and tags it with `test`
 * After building the Foreman container, the Dynflow container is rebuilt and tagged with `test`
 * The deployment code is updated to reference the `test` images
 * A deployment is initiated
 * Smoke tests are ran against the deployment
 * If the smoke tests pass, the `test` images are promoted to `latest` tags

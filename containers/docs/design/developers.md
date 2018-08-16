# Development

This document aims to capture how developers can use a containerized deployment to perform normal development activities. The goal is to provide an environment that mimics the production architecture and enable speed of development.

## Goals

 * Provide as close to production like environment when developing as possible
 * Provide quick feedback to developers when code changes are made
 * Support developers preferred development environments such as local IDEs
 * Provide quick deployment and update of development environments

## Strategies

 1) Local development container connected to services running in Kubernetes
 2) Use of rsync to sync local source into containers on code changes
 3) [Skaffold](https://github.com/GoogleContainerTools/skaffold) or [Draft](https://github.com/Azure/draft) to rebuild and deploy container on code changes

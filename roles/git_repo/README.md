This role clones a set of git repositories, handling multiple remotes and managing different branches for each remote. It also provides basic support for bundle installs for Ruby projects, and pip installs within a virtual environment for Python projects. The role aims to present a single, simple interface in Ansible variables for managing a collection of locally cloned git repositories.

Role Variables
--------------

The main data structure for the role is the list of `git_repositories`. Each repository in the list requires the following attributes:

- `name`: The local name of the repository.
- `dir`: The parent directory to clone the repository from.
- `remotes`: List of repository remotes, each with `name`, `url`, and `branches`.

Repositories may also have the following optional attributes:

- `install_gems`: Boolean to indicate if Ruby gems should be installed. This assumes the cloned repository provides a Gemfile.
- `python_packages`: A list of python packages to install in a venv within the repository.

Each remote requires the following attributes:

- `name`: Name of the remote.
- `url`: URL of the remote.
- `branches`: A list of branches in the remote repository that will be created in the local clone.

Examples
--------

Basic example of the `git_repositories` variable, configuring two repositories, each with a single remote and a single branch:

```yaml
git_repositories:
  - name: 'foreman'
    dir: '/home/vagrant'
    remotes:
      - name: 'origin'
        url: 'git@github.com/my_github_user/foreman.git'
        branches:
          - 'develop'
  - name: 'katello'
    dir: '/home/vagrant'
    remotes:
      - name: 'origin'
        url: 'git@github.com/my_github_user/katello.git'
        branches:
          - 'master'
```

Example configuring a repository with multiple remotes and branches and installing gems from the project's Gemfile. The checkout will be of the first branch on the first remote when performing the bundle install:

```yaml
git_repositories:
  - name: 'foreman'
    dir: '/home/vagrant'
    remotes:
      - name: 'myfork'
        url: 'git@github.com/my_github_user/foreman.git'
        branches:
          - 'develop'
          - 'exciting-new-feature'
          - 'fix-annoying-bug'
      - name: 'upstream'
        url: 'git@github.com/theforeman/foreman.git'
        branches:
          - '3.9-stable'
          - '3.8-stable'
    install_gems: true
```

Installing Python Packages in a Virtual Environment:

```yaml
git_repositories:
  - name: 'rpm-packaging'
    dir: '/home/vagrant'
    remotes:
      - name: 'downstream'
        url: 'git@gitlab.example.com/systems_management/rpm-packaging.git'
        branches:
          - 'STREAM'
          - 'VERSION-1'
          - 'VERSION-2'
          - 'VERSION-3'
    python_packages:
      - 'ansible'
      - 'obal'
      - 'tito'
```

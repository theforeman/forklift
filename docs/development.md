# Development Environments

This covers how to setup and configure a development environment using the Forklift tool suite.

* [Development Environment Deployment](#development-environment-deployment)
    * [Deploy a Katello Development Environment](#deploy-a-katello-development-environment)
    * [Deploy a Stable Katello Development Box](#deploy-a-stable-katello-development-box)
    * [Starting the Development Server](#starting-the-development-server)
    * [Customizing the Development Environment](#customizing-the-development-environment)
    * [Reviewing Pull Requests](#reviewing-pull-requests)
* [Packit PR Builds](#packit-pr-builds)
* [Test Puppet Module Pull Requests](#test-puppet-module)
* [Hammer Development](#hammer-development)
* [Capsule Development](#capsule-development)
* [Client Development](#client-development)
* [Dynflow](#dynflow-development)
* [Smoker](#smoker)
* [Advanced foreman features](#advanced-features)

## Development Environment Deployment

### Deploy a Katello Development Environment

A Katello development environment can be deployed on Enterprise Linux (EL) distributions. Ensure that you have followed the steps to setup Vagrant and the libvirt plugin. There are a variety of useful development environment options that should or can be set when creating a development box. These options are designed to configure your environment ready to use your own fork, and create pull requests. To create a development box:

1. Copy `vagrant/boxes.d/99-local.yaml.example` to `vagrant/boxes.d/99-local.yaml`.
If you already have a `99-local.yaml`, you can copy the entries in `99-local.yaml.example` to your `99-local.yaml`.
2. Fill in any ansible options, examples:
    * `foreman_devel_github_push_ssh`: Force git to push over SSH when HTTPS remote is configured
    * `ssh_forward_agent`: Forward local SSH keys to the box via ssh-agent
3. Fill in any foreman-installer options, examples:
    * `--katello-devel-use-ssh-fork`: will add your fork by SSH instead of HTTPS
    * `--katello-devel-fork-remote-name`: will change the naming convention for your fork's remote
    * `--katello-devel-upstream-remote-name`: will change the naming convention for the upstream (non-fork) repositories remote
    * `--katello-devel-extra-plugins`: specify other plugins to have setup and configured

For example, if I wanted my upstream remotes to be origin and to install the remote execution and discovery plugins:

```yaml
centos9-katello-devel:
  box: centos9-stream
  ansible:
    playbook: 'playbooks/katello_devel.yml'
    group: 'devel'
    variables:
      katello_devel_github_username: <REPLACE ME>
      foreman_installer_options:
        - "--katello-devel-extra-plugins theforeman/foreman_remote_execution"
        - "--katello-devel-extra-plugins theforeman/foreman_discovery"
        - "--foreman-proxy-content-enable-ostree=true"
```

Lastly, spin up the box (this step might take a long time):

```sh
vagrant up centos9-katello-devel
```

The box can now be accessed via ssh and the Rails server started directly (this assumes you are connecting as the default `vagrant` user):

```sh
vagrant ssh centos9-katello-devel
cd foreman
bundle exec foreman start
```

### Deploy a Stable Katello Development Box

When spinning up a Katello development environment locally, it can take a while to install and isn't always guaranteed to finish successfully. A stable Katello development environment was created to ensure an environment is always available to developers.

The Katello development stable box is named `centos9-katello-devel-stable`. Please see the [documentation on stable boxes](stable_boxes.md) for more information on how to use this box.

After spinning up `centos9-katello-devel-stable`, it's a good idea to pull the latest git branches and update gems and npm packages after spinning up a stable box. If a stable box image hasn't been published in a while, these can be out-of-date:

```sh
git fetch
git pull
bundle install
npm install
```

At this moment, you will have to manually configure any personal customizations such as github remotes.

### Starting the Development Server

Our backend requires a rails server to be running. We also use a webpack server for the more "modern" parts of our front-end UI.
[Webpack](https://webpack.js.org) is a way of bundling up multiple front-end files and assets to a small amount of files to send to the browser.
The files that webpack handles are located in `webpack/` directory found in Foreman, Katello,
and plugin root directories. If you are editing any files in `webpack/` and want to have your changes refresh automatically, you will need a webpack server running.

Because we are using a webpack server in conjunction with a rails server, there are different ways of starting a server depending on your needs and preferences. The following are instructions for starting the server using a base `centos9-katello-devel` box as a starting point.

#### Run a rails and webpack server together using `foreman start`

* Run `bundle exec foreman start` in `~/foreman`
* Navigate to `https://centos9-katello-devel.<hostname>.example.com/` where `<hostname>` is the shortname of your hypervisor (machine your VM is running on) and accept the self-signed certs.
* The initial page load after startup might take a while.
* Everything should be set for you to run `bundle exec foreman start` to start your dev server as needed.

NOTE: The `foreman` in `foreman start` is actually [this gem](https://github.com/ddollar/foreman) and not our `foreman`. It
doesn't allow STDIN, which means it doesn't support local debugging. To use a debugger with `foreman start`, you can use
remote debugging with a tool like [pry-remote](https://github.com/Mon-Ouie/pry-remote). There is a helpful blog post about
remote debugging [here](https://blog.honeybadger.io/remote-debugging-with-byebug-rails-and-pow) with more information.

#### Run the rails server without a webpack server running

If you don't need to do any development in the `webpack/` directories, you can turn the webpack server off and run only the rails server if desired.

* Run `foreman-installer --katello-devel-webpack-dev-server false` to disable the webpack server. You can also set this installer option
in your boxes.yaml entry to configure this on box creation.
* Start the rails server with `bundle exec foreman start rails` in `~/foreman`
    * Alternatively, you can start the rails server with `bundle exec rails s`
    * Or with `source .env && BIND=0.0.0.0 bundle exec puma -w 3 -p $PORT --preload` when you want to define the number of workers

#### Additional info

* `foreman start` can be run with `rails` or `webpack` to start just that server: i.e. `bundle exec foreman start rails`. This can be used to start servers separately.

### Customizing the Development Environment

#### Custom files from git repo

A git repo's contents can be copied to the target user's home directory when spinning up a `centos9-katello-devel` or `centos9-katello-devel-stable` box. This can be done by specifying the `customize_home_git_repo` ansible variable. For example:

```yaml
centos9-katello-devel-stable:
  box_name: katello/katello-devel
  hostname: centos9-katello-devel-stable.example.com
  ansible:
    playbook: 'playbooks/setup_user_devel_environment.yml'
    variables:
      customize_home_git_repo: https://github.com/johnpmitsch/config_settings
```

The contents of the specified repo will be copied to the home directory excluding the `.git` folder and `.gitignore` file.

As an example, you can keep dotfiles such as `.bashrc` in the root of your git repository and install packages [with a `bootstrap` script](#running-a-bootstrap-script) using this structure:

```text
mygitrepo
- .bashrc
- .vimrc
- bootstrap
```

#### Custom local files

You can have files automatically copied over to the target user's home directory when spinning up a `centos9-katello-devel` or `centos9-katello-devel-stable` box. Here are the steps to specify custom files to be copied over:

1. Create the directory `user_devel_env_files/` in Forklift's root directory.
2. Add any files you want to be copied over to your development box to `user_devel_env_files/`

The directory `user_devel_env_files/` is ignored by git so the files won't be checked into version control. The files added to `user_devel_env_files/` will be copied over to the target user's home directory on the development VM when it is created or provisioned.

As an example, you can symlink files that are on your hypervisor to this directory and install packages [with a bootstrap script](#running-a-bootstrap-script)

*Both of the local file and git repo custom file strategies are completely optional and are not required to spin up a development environment*

#### Running a bootstrap script

For both the git and custom local file strategies, you can run commands from a bootstrap script found in root level of the git repo or in `user_devel_env_files`

A file named `bootstrap` will be looked for in the home directory and executed if found. This can be used to run any commands you would like to during provisioning. Be sure use the proper language [shebang](https://en.wikipedia.org/w/index.php?title=Shebang_(Unix)) at the top.

A different script location can specified by using the `customize_home_bootstrap_script` variable. The `customize_home_bootstrap_script` variable needs to be specified in the format `path/to/my/script.sh` (don't prepend with `./`).

#### Managing SSH keys

Github [provides documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/using-ssh-agent-forwarding) on how to manage ssh keys using ssh agent forwarding, this can be useful when deploying forklift boxes.

### Reviewing Pull Requests

It's easy to checkout pull requests from projects that were installed in development environment. All projects are cloned in Vagrant's home, e.g. ~/foreman, ~/katello etc. In order to apply some PR to any of this project, you can use a reviewer script. See following example

```sh
cd ~/katello
rpr 5266
```

`rpr` is shortcut for review pull request. This fetches information about PR number 5266, defines new remote in you .git/config, fetches new objects from it. Then it creates new local branch called review/pr5266 and pulls the code from the PR. It uses SSH connection so using ssh-agent, with SSH key uploaded to your github account, is recommended. If you're applying a PR on remote machine to which you connected through SSH, make sure you open that connection with agent forwarding, e.g. `ssh -a vagrant@host.example.com`. Don't forget to migrate and seed the database if the PR contains related changes. Note that this might create new merge commit so git might want you to set your email and name. You can set that with following commands.

```sh
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

Once reviewing is finished, the repository can be reset to develop/master branch by calling `rrpr`. It destroys the review branch after it checkouts back to master branch.

If `rpr` is used in project with `config/database.yml` it will also create a backup of the db in ./tmp/. When `rrpr` is called later and in case previous backup was found, it asks whether it should be restored.

## Packit PR Builds

Forklift supports using Packit PR builds for testing purposes. To use those one needs to define the `packit_prs` variable to the list of PRs (in the form of `<org>/<repo>/<pr>` or as full PR links):

In `99-local.yaml`:

```yaml
ansible:
  variables:
    packit_prs:
      - "theforeman/foreman_maintain/690"
      - "https://github.com/theforeman/foreman_maintain/pull/690"
```

## Test Puppet Module

### Pull Requests

Testing installer puppet module pull requests is possible through an Ansible variable. Any number of modules and associated pull requests may be specified. For example, if a module under goes a refactoring, and you want to test that it continues to work with the installer. The pull requests are indicated by the github project, repository, and pull request number (eg. katello/qpid/23). Note that the name in this situation is the name as laid down in the module directory as opposed to the github repository name. In other words, use 'qpid' not 'puppet-qpid'. The pull requests are specified through the 'foreman_installer_module_prs' variable in the 'ansible' 'variables' section of your box definition. See examples below.

Single module PR in `99-local.yaml`:

```yaml
ansible:
  variables:
    foreman_installer_module_prs:
      - theforeman/katello_devel/97
```

Multiple modules:

```yaml
ansible:
  variables:
    foreman_installer_module_prs:
      - theforeman/katello_devel/97
      - theforeman/qpid/34
```

### Branches

Testing installer puppet module branches is possible through an Ansible variable. Any number of modules and associated branches may be specified. For example, if a module under goes a refactoring, and you want to test that it continues to work with the installer. The branches are indicated by the github project, repository, and branch (or commit) name (eg. myfork/qpid/my-branch). Note that the name in this situation is the name as laid down in the module directory as opposed to the github repository name. In other words, use 'qpid' not 'puppet-qpid'. The branches are specified through the 'foreman_installer_module_branches' variable in the 'ansible' 'variables' section of your box definition. See examples below.

Single module branch in `99-local.yaml`:

```yaml
ansible:
  variables:
    foreman_installer_module_branches:
      - myfork/katello_devel/switch-to-scl
```

Multiple modules:

```yaml
ansible:
  variables:
    foreman_installer_module_branches:
      - myfork/katello_devel/switch-to-scl
      - myfork/foreman/add-puma
```

## Hammer Development

Hammer is the command line interface (CLI) to Foreman and Katello. It supports plugins
such as [Foreman Tasks](https://github.com/theforeman/hammer-cli-foreman-tasks) and
importing/exporting data via [CSV](https://github.com/Katello/hammer-cli-csv).
The CLI can be configured to work with any version of Foreman. To facilitate
development in Hammer or any of its plugins, a lightweight Vagrant box is
provided in the `boxes.yaml.example` file. To use this functionality, copy the
centos9-hammer-devel configuration from the example file into your `boxes.yaml`
file, changing options as necessary. Then run the following:

```sh
vagrant up centos9-hammer-devel
```

In the Vagrant box, find the Hammer repositories at `/home/vagrant/` and the
configuration at `/home/vagrant/.hammer`.

## Capsule Development

To use this functionality, add the following configuration to your `99-local.yaml`,
changing the hostnames as needed.

### To setup a smart proxy (capsule) and a new development environment

* Setup `99-local.yaml`

```yaml
capsule-dev:
  box: centos9-stream
  ansible:
    playbook: 'playbooks/foreman_proxy_content_dev.yml'
    group: 'foreman-proxy-content'
    server: 'foo'
```

* `vagrant up foo`
* ssh into foo and `rails s`
* spin up new capsule `vagrant up capsule-dev`

### To setup a capsule with an existing development environment

* Add the following to the existing Katello development server's configuration in `99-local.yaml`

```yaml
  ansible:
    group: 'server'
```

* Add a box for a capsule, using the katello server's name in the "server" field:

```yaml
capsule-dev:
  box: centos9-stream
  ansible:
    playbook: 'playbooks/foreman_proxy_content_dev.yml'
    group: 'foreman-proxy-content'
    server: 'your-katello-server-name'
```

* ssh into existing development server and `rails s`
* spin up new capsule `vagrant up capsule-dev`

## Client Development

`99-local.yaml` defines a `katello-client` box which can be used to register against a Katello instance.
The following example shows some of the extra values that can be set to control how the client is registered.

```yaml
katello-client:
  box: centos9-stream
  ansible:
    playbook: 'playbooks/katello_client.yml'
    group: 'client'
    variables:
      katello_client_server: 'centos9-katello-devel'
      katello_client_organization: 'Default_Organization'
      katello_client_environment: 'Library'
      katello_client_username: 'admin'
      katello_client_password: 'changeme'
      katello_client_install_agent: True
```

## Dynflow Development

DYNamic workFLOW orchestration engine [https://dynflow.github.io](https://dynflow.github.io)

To use this box, copy the configuration from `boxes.yaml.example` to
`boxes.yaml`, changing options as necessary, then run the following:

```sh
vagrant up centos9-dynflow-devel
```

In the Vagrant box, the dynflow repository is cloned to `/home/vagrant/dynflow`.

## Smoker

The testing tool [smoker](https://github.com/theforeman/smoker) can be set up with the `centos9-foreman-smoker` box and tests can be run against a separate Foreman/Katello instance.

To use:

1. Ensure that you have a running instance of Foreman/Katello.
2. Follow the example box definition in `vagrant/boxes.d/99-local.yaml.example` for `centos9-foreman-smoker` and update the `smoker_base_url` variable. With `pytest_run_tests` set to false, smoker tests will not be run by the playbook, but the box will be set up with pytest and the smoker repository will be cloned to the `vagrant` user's home directory.
3. Run `vagrant up centos9-foreman-smoker`. A debug message will print showing the command to run smoker tests and the alias that has been set up. The alias is defined in `~/.bash_profile` on the box itself.
4. You can then ssh into the smoker box. Ensure the hostname of the Foreman/Katello instance can be reached by the smoker box.
5. From the smoker box, run tests as the Vagrant user using the alias or running pytest commands manually. To change the testing options, please see [the smoker documentation](https://github.com/theforeman/smoker) and modify the alias or manually run pytest commands as necessary.

## Advanced features

These are playbooks, roles and variables provided to use additional functionalities to test advanced foreman features.
This list should be organized by foreman feature.

* [Kerberos](#foreman-with-active-directory)

### Foreman with Active Directory

#### Prepare AD controller

You need the AD controller with domain controller you want to test this against.
Easiest is to install Windows server (ideally core to save resources, but its harder to install AD and setup DNS).
This controller doesn't need to be searchable in your environment, we will point libvirt there.

I will be using the domain `example.com` and expect your AD controller runs on IP `192.0.2.8`.

#### Setup libvirt

Here we will edit the libvirt network, so its dnsmasq points the domain request to our controller.
If you are using another provider, you are on your own to setup the internal dns lookups.

Edit the libvirt network (`virsh net-edit network` or virt-manager -> connection details -> networks).
Add the xmlns scope so the xml is valid and the dnsmasq option to point all `example.com` requests to our AD controller:

```xml
<network xmlns:dnsmasq="http://libvirt.org/schemas/network/dnsmasq/1.0">
  ....
  <dnsmasq:options>
    <dnsmasq:option value="server=/example.com/192.0.2.8"/>
  </dnsmasq:options>
</network>
```

#### Setup forklift machine

Then add the machine and specify the domain, playbook and password for the join user.
I'm using a short name as longer names tend to have issues with NETBIOS names that end up shortened, and hostname != NETBIOS name could cause issues.
If you choose longer name you're on your own, contributions with fixes welcome! :)

```yaml
# boxes.d/99-local.yaml

foreman-ad:
  box: centos9-stream
  memory: 4096
  domain: 'example.com' # must be the AD domain
  ansible:
    playbook: 'playbooks/foreman_with_ad.yml'
    group: server
    variables:
      foreman_realm_directory_admin_password: 'Admin123.'
```

#### Provision

Provision it:

```sh
vagrant up foreman-ad
```

Test it:

```console
$ vagrant ssh foreman-ad

foreman-ad$ kinit test-domain-user # initialize Kerberos with an existing user in the AD domain
foreman-ad$ klist # verify the above went smooth
foreman-ad$ curl -k -u : --negotiate https://foreman-ad.example.com/users/extlogin # substitute for your fqdn

<html><body>You are being <a href="https://foreman-ad.example.com/users/4-ldapuserexample-com/edit">redirected</a>.</body></html>
```

If you've got You are being redirected message, everything worked and you are "all set".

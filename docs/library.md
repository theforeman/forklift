# Using Forklift as a Library

Instead of writing a plugin, Forklift can be used as a library to gain more control over what is loaded and when. This will walk through an example use of this. In this example the goal is to be able to provide a custom set of base boxes, our own roles, playbooks and pipelines.

First, make our example directory and clone Forklift:

    mkdir example
    cd example
    git clone https://github.com/theforeman/forklift.git

First, add an `ansible.cfg` file:

```
[defaults]
nocows = 1
host_key_checking = False
retry_files_enabled = False
roles_path = $PWD/galaxy_roles:$PWD/roles:$PWD/forklift/playbooks/roles
callback_plugins = $PWD/forklift/playbooks/callback_plugins/
inventory = forklift/playbooks/inventory/vagrant.py
```

Now, make directories for playbooks and roles:

    mkdir playbooks
    mkdir roles
    mkdir pipelines

Deploy a file with the base set of boxes the plugin requires:

    vim base_boxes.yaml

```yaml
centos7:
  box_name:   'centos/7'
  image_name: !ruby/regexp '/CentOS 7.*PV/'
  pty:        true
```

Next, deploy a Vagrantfile that creates a box loader, adds the base boxes defined in the plugin and then call the distributor so Vagrant knows about the boxes:

```ruby
require "#{File.dirname(__FILE__)}/forklift/lib/forklift"

loader = Forklift::BoxLoader.new
loader.add_boxes("base_boxes.yaml")
distributor = Forklift::BoxDistributor.new(loader.boxes)
distributor.distribute
```

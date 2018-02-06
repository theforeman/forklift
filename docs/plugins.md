# Plugins

Any file on path `./plugins/*/Vagrantfile` will be loaded on `./Vagrantfile` evaluation. `plugins` directory is ignored by git therefore other git repositories can be cloned into `plugins` to add custom machines.

Example of a plugin's `Vagrantfile`:

```ruby
module APlugin

  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    DB           = 'db'
    WEB          = 'web'
    PARENT_NAME  = 'centos7-devel'
    PROJECT_PATH = "#{Forklift::ROOT}/../a_repo"

    Forklift.define_vm config, Forklift.new_box(PARENT_NAME, DB) do |machine|
      machine.vm.provision :shell do |shell|
        shell.inline = 'echo doing DB box provisioning'
        config.vm.synced_folder PROJECT_PATH, "/home/vagrant/a_repo"
        config.vm.provider :virtualbox do |domain|
          domain.memory = 1024
        end
      end
    end

    Forklift.define_vm config, Forklift.new_box(PARENT_NAME, WEB) do |machine|
      machine.vm.provision :shell do |shell|
        shell.inline = 'echo doing WEB box provisioning'
        shell.inline = 'echo doing another WEB box provisioning'
        config.vm.synced_folder PROJECT_PATH, "/home/vagrant/a_repo"
        config.vm.provider :virtualbox do |domain|
          domain.memory = 512
        end
      end
    end
  end
end
```

If you would like to inject hostname management and package caching without
updating the base Vagrantfile,  you can install the `vagrant-hostname` and
`vagrant-cachier` plugins and then create
`./plugins/my-custom-plugins/Vagrantfile` with the following content:

```ruby

# this enables some customizations that should not be used until after you have a
# working basic install.

module MyCustomPlugins
  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    # set up some shared dirs
    config.vm.synced_folder "/path/to/local/checkout/katello", "/home/vagrant/share/katello", type: "nfs"
    config.vm.synced_folder "/path/to/local/checkout/foreman", "/home/vagrant/share/foreman", type: "nfs"
    config.vm.synced_folder "/path/to/local/checkout/foreman-gutterball", "/home/vagrant/share/foreman-gutterball", type: "nfs"

    if Vagrant.has_plugin?("vagrant-hostmanager")
      config.hostmanager.enabled = true
      config.hostmanager.manage_host = true
    end

    if Vagrant.has_plugin?("vagrant-cachier")
      # Configure cached packages to be shared between instances of the same base box.
      # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
      config.cache.scope = :box
      # disable gem caching for now, due to permissions issue
      config.cache.auto_detect = false
      config.cache.enable :yum

      config.cache.synced_folder_opts = {
        type: :nfs,
        mount_options: ['rw', 'vers=4', 'tcp', 'nolock']
      }
    end
  end
end
```

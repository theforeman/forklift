require 'yaml'
require './lib/katello_deploy'

VAGRANTFILE_API_VERSION = '2'
SUPPORT_SSH_INSERT_KEY = Gem.loaded_specs['vagrant'].version >= Gem::Version.create('1.7')

module KatelloDeploy
  @box_loader = BoxLoader.new
  @boxes = @box_loader.add_boxes('config/base_boxes.yaml')
  @boxes = @box_loader.add_boxes('boxes.yaml') if File.exists?('boxes.yaml')

  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    @boxes.each do |name, box|
      define_vm config, box
    end

    config.vm.provider :libvirt do |domain|
      domain.memory = 3560
      domain.cpus   = 2
    end

    config.vm.provider :virtualbox do |domain|
      domain.memory = 3560
      domain.cpus   = 2
      domain.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
      domain.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
    end
  end

  def self.plugin_vagrantfiles
    current = File.dirname(__FILE__)
    Dir.glob "#{current}/plugins/*/Vagrantfile"
  end

  plugin_vagrantfiles.each { |f| load f }

  def self.define_vm(config, box = {})
    config.vm.define box.fetch('name'), primary: box.fetch('default', false) do |machine|
      machine.vm.box = box.fetch('box_name')
      machine.vm.box_check_update = true
      machine.vm.box_url = box.fetch('box_url') if box.key?('box_url')
      machine.vm.hostname = "#{box.fetch('name').to_s.gsub('.','-')}.example.com"
      config.ssh.insert_key = false if SUPPORT_SSH_INSERT_KEY

      if box['shell']
        machine.vm.provision :shell do |shell|
          shell.inline = box.fetch('shell')
          shell.privileged = false if box.key?('privileged')
        end
      end

      if box.key?('libvirt')
        machine.vm.provider :libvirt do |p, override|
          override.vm.box_url = box.fetch('libvirt')
          override.vm.synced_folder ".", "/vagrant", type: "rsync"
          override.vm.network :public_network, :dev => box.fetch('bridged'), :mode => 'bridge' if box.fetch('bridged', false)
          p.cpus = box.fetch('cpus') if box.fetch('cpus', false)
          p.memory = box.fetch('memory') if box.fetch('memory', false)
        end
      end

      if box.key?('virtualbox')
        machine.vm.provider :virtualbox do |p, override|
          override.vm.box_url = box.fetch('virtualbox')
          p.cpus = box.fetch('cpus') if box.fetch('cpus', false)
          p.memory = box.fetch('memory') if box.fetch('memory', false)

          if box.fetch('name').to_s.include?('devel')
            config.vm.network :forwarded_port, guest: 3000, host: 3330
            config.vm.network :forwarded_port, guest: 443, host: 4430
          else
            override.vm.network :forwarded_port, guest: 80, host: 8080
            override.vm.network :forwarded_port, guest: 443, host: 4433
          end
        end

      end

      if box.fetch('image_name', false)
        machine.vm.provider :rackspace do |p, override|
          override.vm.box  = 'dummy'
          p.server_name    = machine.vm.hostname
          p.flavor         = /4GB/
          p.image          = box.fetch('image_name')
          override.ssh.pty = true if box.fetch('pty')
        end
      end

      yield machine if block_given?
    end
  end


end


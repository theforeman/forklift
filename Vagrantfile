# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require "#{File.dirname(__FILE__)}/lib/forklift"

VAGRANTFILE_API_VERSION = '2'
SUPPORT_SSH_INSERT_KEY = Gem.loaded_specs['vagrant'].version >= Gem::Version.create('1.7')
SUPPORT_NAMED_PROVISIONERS = Gem.loaded_specs['vagrant'].version >= Gem::Version.create('1.7')
SUPPORT_BOX_CHECK_UPDATE = Gem.loaded_specs['vagrant'].version >= Gem::Version.create('1.5')
VAGRANTFILE_DIR = File.dirname(__FILE__)

module Forklift

  def self.plugin_base_boxes
    current = File.dirname(__FILE__)
    base_boxes = Dir.glob "#{current}/plugins/*/base_boxes.yaml"
    base_boxes.each { |boxes| add_boxes(boxes) }
  end

  def self.plugin_vagrantfiles
    current = File.dirname(__FILE__)
    Dir.glob "#{current}/plugins/*/Vagrantfile"
  end

  def self.add_boxes(boxes)
    @boxes = @box_loader.add_boxes(boxes, "#{VAGRANTFILE_DIR}/config/versions.yaml")
  end

  def self.define_vm(config, box = {})
    config.vm.define box.fetch('name'), primary: box.fetch('default', false) do |machine|
      machine.vm.box = box.fetch('box_name')
      machine.vm.box_check_update = true if SUPPORT_BOX_CHECK_UPDATE
      machine.vm.box_url = box.fetch('box_url') if box.key?('box_url')
      config.ssh.insert_key = false if SUPPORT_SSH_INSERT_KEY

      if box.fetch('hostname', false)
        machine.vm.hostname = box.fetch('hostname')
      else
        machine.vm.hostname = "#{box.fetch('name').to_s.gsub('.','-')}.example.com"
      end

      networks = box.fetch('networks', [])
      networks = networks.map do |network|
        network['options'] = network['options'].inject({}){ |memo,(k,v)| memo.update(k.to_sym => v) }
      end

      if box.key?('shell') && !box['shell'].nil?
        machine.vm.provision :shell do |shell|
          shell.inline = box.fetch('shell')
          shell.privileged = false if box.key?('privileged')
        end
      end

      networks = box.fetch('networks', [])
      networks = networks.map do |network|
        symbolized_options = network['options'].inject({}){ |memo,(k,v)| memo.update(k.to_sym => v) }
        network.update('options' => symbolized_options)
      end

      if box.key?('ansible')
        unless @ansible_groups["#{box['ansible']['group']}"]
          @ansible_groups["#{box['ansible']['group']}"] = []
        end

        @ansible_groups["#{box['ansible']['group']}"] << box.fetch('name')

        if box['ansible'].key?('server')
          @ansible_groups["server-#{box.fetch('name')}"] = box['ansible']['server']
        end

        @host_vars = {box['name'] => box['ansible']['variables']}

        if (playbooks = box['ansible']['playbook'])
          [playbooks].flatten.each_with_index do |playbook, index|
            args = SUPPORT_NAMED_PROVISIONERS ? ["main#{index}", type: 'ansible'] : [:ansible]
            machine.vm.provision(*args) do |ansible|
              ansible.playbook = playbook
              ansible.host_vars = @host_vars if @host_vars && Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
              ansible.groups = @ansible_groups
            end
          end
        end
      end

      machine.vm.provider :libvirt do |p, override|
        override.vm.box_url = box.fetch('libvirt') if box.fetch('libvirt', false)
        override.vm.synced_folder ".", "/vagrant", type: "rsync"
        override.vm.network :public_network, :dev => box.fetch('bridged'), :mode => 'bridge' if box.fetch('bridged', false)
        networks.each do |network|
          override.vm.network network['type'], network['options']
        end
        p.cpus = box.fetch('cpus') if box.fetch('cpus', false)
        p.memory = box.fetch('memory') if box.fetch('memory', false)
        p.machine_virtual_size = box.fetch('disk_size') if box.fetch('disk_size', false)
      end

      machine.vm.provider :virtualbox do |p, override|
        override.vm.box_url = box.fetch('virtualbox') if box.fetch('virtualbox', false)
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

  @box_loader = BoxLoader.new
  @boxes = @box_loader.add_boxes("#{VAGRANTFILE_DIR}/config/base_boxes.yaml", "#{VAGRANTFILE_DIR}/config/versions.yaml")
  plugin_vagrantfiles.each { |f| load f }
  plugin_base_boxes
  @boxes = @box_loader.add_boxes("#{VAGRANTFILE_DIR}/boxes.yaml", "#{VAGRANTFILE_DIR}/config/versions.yaml") if File.exists?("#{VAGRANTFILE_DIR}/boxes.yaml")
  @boxes  = @boxes.keys.sort.inject({}) do |hash, key|
    hash[key] = @boxes[key]
    hash
  end

  @ansible_groups = {}


  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    if Vagrant.has_plugin?("vagrant-hostmanager")
      config.hostmanager.enabled = true
      config.hostmanager.manage_host = true
      config.hostmanager.manage_guest = true
      config.hostmanager.include_offline = true
    end

    if Vagrant.has_plugin?("vagrant-cachier")
      config.cache.scope = :box
      config.cache.synced_folder_opts = {
        type: :nfs,
        mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
      }
    end

    @boxes.each do |name, box|
      define_vm config, box
    end

    config.vm.provider :libvirt do |domain|
      domain.memory = 4608
      domain.cpus   = 2
    end

    config.vm.provider :virtualbox do |domain|
      domain.memory = 4608
      domain.cpus   = 2
      domain.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
      domain.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
    end
  end


end

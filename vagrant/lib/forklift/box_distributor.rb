# frozen_string_literal: true

require_relative 'settings'

module Forklift
  class BoxDistributor

    VAGRANTFILE_API_VERSION = '2'.freeze

    def initialize(boxes)
      @ansible_groups = {}
      @boxes = boxes
      @boxes = @boxes.keys.sort.each_with_object({}) do |key, hash|
        hash[key] = @boxes[key]
        hash
      end
      @settings = settings
    end

    def settings
      default_settings = {
        'memory' => 6144,
        'cpus' => 2,
        'scale_memory' => 1,
        'scale_cpus' => 1,
        'sync_type' => 'rsync',
        'cachier' => {
          'mount_options' => ['rw', 'vers=3', 'tcp', 'nolock']
        },
        'cachier_enabled' => true,
        'hostmanager_enabled' => true
      }

      overrides = Settings.new.settings

      default_settings.merge(overrides)
    end

    def distribute!
      Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
        configure_vagrant_hostmanager(config)
        configure_vagrant_cachier(config)

        @boxes.each_value do |box|
          define_vm config, box
        end

        config.vm.provider :libvirt do |domain|
          domain.memory = @settings['memory']
          domain.cpus   = @settings['cpus']
          domain.random :model => 'random'
        end

        config.vm.provider :virtualbox do |domain|
          domain.memory = @settings['memory']
          domain.cpus   = @settings['cpus']
          domain.customize ['modifyvm', :id, '--natdnsproxy1', 'off']
          domain.customize ['modifyvm', :id, '--natdnshostresolver1', 'off']
        end
      end
    end

    def fetch_from_box_or_settings(box, key)
      box.fetch(key) { @settings.fetch(key, nil) }
    end

    def define_vm(config, box = {})
      primary = box.fetch('primary', false)
      autostart = box.fetch('autostart', false)
      config.vm.define box.fetch('name'), primary: primary, autostart: autostart do |machine|
        machine.vm.box = box.fetch('box_name', nil)
        machine.vm.box_version = box.fetch('box_version', nil)

        %w[username forward_agent keys_only].each do |key|
          unless (value = fetch_from_box_or_settings(box, "ssh_#{key}")).nil?
            machine.ssh.send("#{key}=", value)
          end
        end

        machine.vm.box_check_update = box.fetch('box_check_update', true)

        machine.vm.box_url = box.fetch('box_url') if box.key?('box_url')

        machine.vm.hostname = if box.fetch('hostname', false)
                                box.fetch('hostname')
                              else
                                domain = create_domain(box)
                                "#{box.fetch('name').to_s.tr('.', '-')}.#{domain}"
                              end

        resize_disk(machine) if box.fetch('disk_size', false)

        networks = configure_networks(box.fetch('networks', []))
        configure_shell(machine, box)
        configure_ansible(machine, box['ansible'], box['name'])
        configure_providers(machine, box, networks)
        configure_synced_folders(machine, box)
        configure_private_network(machine, box)
        configure_sshfs(machine, box)
        configure_nfs(config, box)

        yield machine if block_given?
      end
    end

    def resize_disk(machine)
      machine.vm.provision('disk_resize', type: 'ansible') do |ansible_provisioner|
        ansible_provisioner.playbook = 'playbooks/resize_disk.yml'
      end
    end

    def create_domain(box)
      box['domain'] || @settings['domain'] || "#{`hostname -s`.strip.downcase}.example.com"
    end

    def configure_nfs(config, box)
      normalize_synced_folder(box['nfs']).each do |nfs|
        config.vm.synced_folder nfs['host_path'],
                                nfs['guest_path'],
                                :type => :nfs,
                                :nfs_udp => nfs['udp'] || false,
                                :linux__nfs_options => nfs['options'] || %w[async rw no_subtree_check all_squash]
      end
    end

    def configure_sshfs(machine, box)
      normalize_synced_folder(box['sshfs']).each do |sshfs|
        machine.vm.synced_folder sshfs['host_path'],
                                 sshfs['guest_path'],
                                 :type => :sshfs,
                                 :reverse => sshfs['reverse'] || false,
                                 :sshfs_opts_append => sshfs['options'] || ''
      end
    end

    def configure_vagrant_hostmanager(config)
      return unless Vagrant.has_plugin?('vagrant-hostmanager')
      return unless @settings['hostmanager_enabled']

      config.hostmanager.enabled = true
      config.hostmanager.manage_host = true
      config.hostmanager.manage_guest = true
      config.hostmanager.include_offline = true

      return unless (dev = @settings['hostmanager_ip_resolver_device'])

      config.hostmanager.ip_resolver = proc do |vm|
        if vm.ssh_info && vm.ssh_info[:host]
          result = ''
          vm.communicate.execute("ip addr show #{dev}") do |type, data|
            result = "#{result}#{data}" if type == :stdout
          end
          (ip = /inet (\d+\.\d+\.\d+\.\d+)/.match(result)) && ip[1]
        end
      end
    end

    def configure_vagrant_cachier(config)
      return unless Vagrant.has_plugin?('vagrant-cachier')
      return unless @settings['cachier_enabled']

      config.cache.scope = :box
      config.cache.synced_folder_opts = {
        type: :nfs,
        mount_options: @settings['cachier']['mount_options']
      }
    end

    def configure_networks(networks)
      return [] if networks.empty?

      networks.map do |network|
        network.update('options' => symbolized_options(network['options']))
      end
    end

    def configure_ansible(machine, ansible, box_name)
      return unless ansible

      if ansible.key?('group') && !ansible['group'].nil?
        @ansible_groups[ansible['group'].to_s] ||= []
        @ansible_groups[ansible['group'].to_s] << box_name
      end

      if ansible.key?('server') && !ansible['server'].nil?
        @ansible_groups["server-#{box_name}"] = ansible['server']
      end

      return unless (playbooks = ansible['playbook'])

      [playbooks].flatten.each_with_index do |playbook, index|
        machine.vm.provision("main#{index}", type: 'ansible') do |ansible_provisioner|
          ansible_provisioner.compatibility_mode = '2.0'
          ansible_provisioner.playbook = playbook
          ansible_provisioner.extra_vars = ansible['variables']
          ansible_provisioner.groups = @ansible_groups
          ansible_provisioner.verbose = ansible['verbose'] || false
          %w[config_file galaxy_role_file inventory_path].each do |key|
            if (value = ansible[key])
              ansible_provisioner.send("#{key}=", value)
            end
          end
        end
      end
    end

    def configure_shell(machine, box)
      return unless box.key?('shell') && !box['shell'].nil?

      machine.vm.provision :shell do |shell|
        shell.inline = box.fetch('shell')
        if box.key?('shell_args')
          shell.args = box.fetch('shell_args')
        end
        shell.privileged = false if box.key?('privileged')
      end
    end

    # Configures synced folders defined for the box
    # and the private network required for them
    def configure_synced_folders(machine, box)
      synced_folders = box.fetch('synced_folders', [])
      return if synced_folders.empty?

      synced_folders.each do |folder|
        options = symbolized_options(folder['options'])
        machine.vm.synced_folder folder['path'], folder['mount_point'], options
      end
    end

    def configure_private_network(machine, box)
      ip = box.fetch('private_ip', nil)
      return if ip.nil?

      options = {}.tap do |hash|
        if ip
          hash[:ip] = ip
        else
          hash[:type] = 'dhcp'
        end
      end
      machine.vm.network :private_network, options
    end

    def configure_providers(machine, box, networks = [])
      configure_libvirt(machine, box, networks)
      configure_virtualbox(machine, box, networks)
      configure_openstack_provider(machine, box)
      configure_google_provider(machine, box)
      configure_docker_provider(machine, box)
    end

    def configure_libvirt(machine, box, networks = [])
      machine.vm.provider :libvirt do |p, override|
        override.vm.box_url = box.fetch('libvirt') if box.fetch('libvirt', false)
        override.vm.synced_folder '.', '/vagrant', type: @settings['sync_type'], rsync__args: ['--max-size=100m'],
                                                   disabled: @settings['sync_type'] == 'disabled'

        if box.fetch('bridged', false)
          override.vm.network :public_network, :dev => box.fetch('bridged'), :mode => 'bridge'
        end
        networks.each do |network|
          override.vm.network network['type'], **network['options']
        end
        p.cpus = box.fetch('cpus').to_i * @settings['scale_cpus'].to_i if box.fetch('cpus', false)
        p.cpu_mode = box.fetch('cpu_mode') if box.fetch('cpu_mode', false)
        p.memory = box.fetch('memory').to_i * @settings['scale_memory'].to_i if box.fetch('memory', false)
        p.machine_virtual_size = box.fetch('disk_size') if box.fetch('disk_size', false)
        p.management_network_domain = create_domain(box) if p.respond_to?(:management_network_domain)
        p.qemu_use_session = @settings['libvirt_qemu_use_session'] if @settings.key?('libvirt_qemu_use_session')

        add_disks(box, p)

        merged_options(box, 'libvirt_options').each do |opt, val|
          p.instance_variable_set("@#{opt}", val)
        end
      end
    end

    def configure_virtualbox(machine, box, networks = [])
      machine.vm.provider :virtualbox do |p, override|
        override.vm.box_url = box.fetch('virtualbox') if box.fetch('virtualbox', false)
        p.cpus = box.fetch('cpus').to_i * @settings['scale_cpus'].to_i if box.fetch('cpus', false)
        p.memory = box.fetch('memory').to_i * @settings['scale_memory'].to_i if box.fetch('memory', false)

        bridged = box.fetch('bridged', false)

        if bridged
          override.vm.network :public_network, bridge: bridged
        elsif box.fetch('name').to_s.include?('devel')
          override.vm.network :forwarded_port, guest: 3000, host: 3330
          override.vm.network :forwarded_port, guest: 443, host: 4430
        else
          override.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true
          override.vm.network :forwarded_port, guest: 443, host: 4433, auto_correct: true
        end

        networks.each do |network|
          override.vm.network network['type'], **network['options']
        end

        merged_options(box, 'virtualbox_options').each do |opt, val|
          p.instance_variable_set("@#{opt}", val)
        end
      end
    end

    def configure_openstack_provider(machine, box)
      machine.vm.provider :openstack do |p, override|
        override.vm.box = nil
        if box.fetch('sync_type', 'disabled')
          override.vm.synced_folder '.', '/vagrant', disabled: true
        end
        override.ssh.pty       = true if box.fetch('pty', nil)
        override.ssh.username  = box.fetch('username', 'root')
        p.server_name          = machine.vm.hostname
        p.flavor               = box.fetch('openstack_flavor', /4GB/)
        p.image                = box.fetch('image_name', nil)
        p.meta_args_support    = true

        merged_options(box, 'openstack_options').each do |opt, val|
          p.instance_variable_set("@#{opt}", val)
        end
      end
    end

    def configure_google_provider(machine, box)
      machine.vm.provider :google do |p, override|
        override.ssh.private_key_path = '~/.ssh/id_rsa'

        p.google_project_id = @settings['google_project_id']
        p.google_client_email = @settings['google_client_email']
        p.google_json_key_location = @settings['google_json_key_location']

        override.vm.box = 'google/gce'

        merged_options(box, 'google_options').each do |opt, val|
          p.instance_variable_set("@#{opt}", val)
        end
      end
    end

    def configure_docker_provider(machine, box)
      machine.vm.provider :docker do |p|
        merged_options(box, 'docker_options').each do |opt, val|
          p.instance_variable_set("@#{opt}", val)
        end
      end
    end

    private

    def add_disks(box, provider)
      box.fetch('add_disks', []).each do |disk|
        type = disk.fetch('type', 'raw')
        device = disk.fetch('device')
        size = disk.fetch('size')
        if type.nil? || device.nil? || size.nil?
          raise "Error in add_disks configuration: type, device or size are missing #{disk}"
        end

        provider.storage :file, :size => size, :type => type, :device => device
      end
    end

    def symbolized_options(hash)
      hash.inject({}) { |memo, (k, v)| memo.update(k.to_sym => v) }
    end

    def merged_options(box, key)
      options = @settings.fetch(key, {})
      options.merge(box.fetch(key, {}))
    end

    def normalize_synced_folder(folder_definition)
      if folder_definition.nil?
        []
      elsif folder_definition.is_a? Hash
        [folder_definition]
      else
        folder_definition
      end
    end

  end
end

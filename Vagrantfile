require "yaml"

VAGRANTFILE_API_VERSION = "2"

module KatelloDeploy
  BATS_SHELL    = "/vagrant/bats/bootstrap_vagrant.sh"
  INSTALL_SHELL = "yum -y install ruby && cd /vagrant && ./setup.rb "
  ROOT          = File.dirname File.expand_path(__FILE__)

  BASE_BOXES = {
    :centos6 => {
      :box_name   => 'centos6',
      :image_name => /CentOS 6\.5/,
      :default    => true,
      :pty        => true,
      :virtualbox => 'http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130731.box',
      :libvirt    => 'http://m0dlx.com/files/foreman/boxes/centos64.box'
    },
    :centos7 => {
      :box_name   => 'centos7',
      :image_name => /CentOS 7/,
      :default    => true,
      :pty        => true,
      :libvirt    => 'https://download.gluster.org/pub/gluster/purpleidea/vagrant/centos-7.0/centos-7.0.box'
    },
  }

  BOXES = [
    { :name => 'centos6', :shell_args => "#{INSTALL_SHELL}" }.merge(BASE_BOXES[:centos6]),
    { :name => 'centos6-2.0', :shell_args => "#{INSTALL_SHELL} --version=2.0" }.merge(BASE_BOXES.fetch(:centos6)),
    { :name => 'centos6-bats', :shell_args => BATS_SHELL }.merge(BASE_BOXES.fetch(:centos6)),
    { :name => 'centos6-devel', :shell_args => "#{INSTALL_SHELL} --devel" }.merge(BASE_BOXES.fetch(:centos6)),
    { :name => 'centos7', :shell_args => "#{INSTALL_SHELL}" }.merge(BASE_BOXES.fetch(:centos7)),
    { :name => 'centos7-2.0', :shell_args => "#{INSTALL_SHELL} --version=2.0" }.merge(BASE_BOXES.fetch(:centos7)),
    { :name => 'centos7-bats', :shell_args => BATS_SHELL }.merge(BASE_BOXES.fetch(:centos7)),
    { :name => 'centos7-devel', :shell_args => "#{INSTALL_SHELL} --devel" }.merge(BASE_BOXES[:centos7]),
  ]

  CUSTOM_BOXES = (File.exists?('boxes.yaml') && YAML::load(File.open('boxes.yaml'))) || {}

  def self.new_box(base, name)
    if box = BOXES.find { |b| b.fetch(:name) == base }
      box.merge(:name => name)
    end
  end

  def self.define_vm(config, box = {})
    config.vm.define box.fetch(:name), primary: box.fetch(:default) do |machine|
      machine.vm.box      = box.fetch(:box_name)
      machine.vm.hostname = "katello-#{box.fetch(:name)}.example.com"

      if box[:shell_args]
        machine.vm.provision :shell do |shell|
          shell.inline = box.fetch(:shell_args)
        end
      end

      machine.vm.provider :libvirt do |p, override|
        override.vm.box_url = box.fetch(:libvirt)
        override.vm.synced_folder ".", "/vagrant", type: "rsync"
      end

      if box.key? :virtualbox
        machine.vm.provider :virtualbox do |p, override|
          override.vm.box_url = box.fetch(:virtualbox)

          if box.fetch(:name).include?('devel')
            config.vm.network :forwarded_port, guest: 3000, host: 3330
            config.vm.network :forwarded_port, guest: 443, host: 4430
          else
            override.vm.network :forwarded_port, guest: 80, host: 8080
            override.vm.network :forwarded_port, guest: 443, host: 4433
          end
        end

      end

      machine.vm.provider :rackspace do |p, override|
        override.vm.box  = 'dummy'
        p.server_name    = machine.vm.hostname
        p.flavor         = /4GB/
        p.image          = box.fetch(:image_name)
        override.ssh.pty = true if box.fetch(:pty)
      end

      yield machine if block_given?
    end
  end

  CUSTOM_BOXES.each do |name, args|
    if (box = new_box(args['box'], name))
      box[:shell_args] += " #{args['options']} " if args['options']
      box[:shell_args] += " --installer-options='#{args['installer']}' " if args['installer']

      BOXES << box
    end
  end

  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    BOXES.each do |box|
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

end


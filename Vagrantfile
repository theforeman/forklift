VAGRANTFILE_API_VERSION = "2"

base_boxes = {
  :centos6 => {
    :box_name => 'centos6',
    :image_name => /CentOS 6\.5/,
    :default => true,
    :pty => true,
    :virtualbox => 'http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130731.box',
    :libvirt => 'http://m0dlx.com/files/foreman/boxes/centos64.box'
  },
  :centos7 => {
    :box_name => 'centos7',
    :image_name => /CentOS 7/,
    :default => true,
    :pty => true,
    :libvirt => 'https://download.gluster.org/pub/gluster/purpleidea/vagrant/centos-7.0/centos-7.0.box'
  },
}

boxes = [
  {:name => 'centos6', :shell_args => 'centos6'}.merge(base_boxes[:centos6]),
  {:name => 'centos6-bats', :shell_args => './bats/bootstrap_vagrant.sh'}.merge(base_boxes[:centos6]),
  {:name => 'centos6-devel', :shell_args => 'centos6 --devel'}.merge(base_boxes[:centos6]),
  {:name => 'centos7', :shell_args => 'centos7'}.merge(base_boxes[:centos7]),
  {:name => 'centos7-bats', :shell_args => './bats/bootstrap_vagrant.sh'}.merge(base_boxes[:centos7]),
  {:name => 'centos7-devel', :shell_args => 'centos7 --devel'}.merge(base_boxes[:centos7]),
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  boxes.each do |box|
    config.vm.define box[:name], primary: box[:default] do |machine|
      machine.vm.box = box[:box_name]
      machine.vm.hostname = "katello-#{box[:name]}.example.com"

      machine.vm.provision :shell do |shell|
        shell.inline = "yum -y install ruby && cd /vagrant && ./setup.rb #{box[:shell_args]}"
      end

      machine.vm.provider :libvirt do |p, override|
        override.vm.box_url = box[:libvirt]
        override.vm.synced_folder ".", "/vagrant", type: "rsync"
      end

      machine.vm.provider :virtualbox do |p, override|
        override.vm.box_url = box[:virtualbox]

        if box[:name].include?('devel')
          config.vm.network :forwarded_port, guest: 3000, host: 3330
          config.vm.network :forwarded_port, guest: 443, host: 4430
        else
          override.vm.network :forwarded_port, guest: 80, host: 8080
          override.vm.network :forwarded_port, guest: 443, host: 4433
        end
      end

      machine.vm.provider :rackspace do |p, override|
        override.vm.box = 'dummy'
        p.server_name = machine.vm.hostname
        p.flavor = /4GB/
        p.image = box[:image_name]
        override.ssh.pty = true if box[:pty]
      end

    end
  end

  config.vm.provider :libvirt do |domain|
    domain.memory = 3560
    domain.cpus = 2
  end

  config.vm.provider :virtualbox do |domain|
    domain.memory = 3560
    domain.cpus = 2
    domain.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
    domain.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
  end

end

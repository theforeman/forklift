VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "centos" do |centos|
    centos.vm.box = "centos64"
    centos.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130731.box"
    centos.vm.hostname = "centos.installer"

    centos.vm.provision :shell do |shell|
      shell.inline = 'yum -y install ruby && cd /vagrant && ./setup.rb centos6'
    end

    centos.vm.provider :libvirt do |v, virt|
      virt.vm.box_url = 'http://m0dlx.com/files/foreman/boxes/centos64.box'
      virt.vm.synced_folder ".", "/vagrant", type: "rsync"
    end

    centos.vm.provider :virtualbox do |prov, config|
      config.vm.network :forwarded_port, guest: 80, host: 8080
      config.vm.network :forwarded_port, guest: 443, host: 4433
    end
  end

  config.vm.define "centos-devel" do |centos|
    centos.vm.box = "centos64"
    centos.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130731.box"
    centos.vm.hostname = "centos.dev"

    centos.vm.provision :shell do |shell|
      shell.inline = 'yum -y install ruby && cd /vagrant && ./setup.rb --devel centos6'
    end

    centos.vm.provider :libvirt do |v, virt|
      virt.vm.box_url = 'http://m0dlx.com/files/foreman/boxes/centos64.box'
      virt.vm.synced_folder ".", "/vagrant", type: "rsync"
    end

    centos.vm.provider :virtualbox do |prov, config|
      config.vm.network :forwarded_port, guest: 3000, host: 3330
      config.vm.network :forwarded_port, guest: 443, host: 4430
    end
  end

  config.vm.define "f19-devel" do |centos|
    centos.vm.box = "fedora19"
    centos.vm.box_url = "https://dl.dropboxusercontent.com/u/86066173/fedora-19.box"
    centos.vm.hostname = "fedora.dev"


    centos.vm.provision :shell do |shell|
      shell.inline = 'yum -y install ruby && cd /vagrant && ./setup.rb --devel fedora19'
    end

    centos.vm.provider :libvirt do |v, virt|
      virt.vm.box_url = 'http://m0dlx.com/files/foreman/boxes/fedora19.box'
      virt.vm.synced_folder ".", "/vagrant", type: "rsync"
    end

    centos.vm.provider :virtualbox do |prov, config|
      config.vm.network :forwarded_port, guest: 3000, host: 3333
      config.vm.network :forwarded_port, guest: 443, host: 4443
    end
  end

  config.vm.provider :libvirt do |domain|
    domain.memory = 2560
    domain.cpus = 2
  end

  config.vm.provider :virtualbox do |domain|
    domain.memory = 2560
    domain.cpus = 2
    domain.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
    domain.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
  end

end

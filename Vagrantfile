VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "centos" do |centos|
    centos.vm.box = "centos64"
    centos.vm.hostname = "centos.installer"

    centos.vm.provision :shell do |shell|
      shell.path = 'bootstrap.sh'
      shell.args = "'/vagrant' centos"
    end

    centos.vm.provider :libvirt do |v, virt|
      virt.vm.box_url = 'http://m0dlx.com/files/foreman/boxes/centos64.box'
    end
  end

  config.vm.define "centos-devel" do |centos|
    centos.vm.box = "centos64"
    centos.vm.hostname = "centos.installer"

    centos.vm.provision :shell do |shell|
      shell.path = 'bootstrap.sh'
      shell.args = "'/vagrant' centos --devel"
    end

    centos.vm.provider :libvirt do |v, virt|
      virt.vm.box_url = 'http://m0dlx.com/files/foreman/boxes/centos64.box'
    end
  end

  config.vm.define "f19-devel" do |centos|
    centos.vm.box = "fedora19"
    centos.vm.hostname = "fedora.installer"

    centos.vm.provision :shell do |shell|
      shell.path = 'bootstrap.sh'
      shell.args = "'/vagrant' fedora19 --devel"
    end

    centos.vm.provider :libvirt do |v, virt|
      virt.vm.box_url = 'http://m0dlx.com/files/foreman/boxes/fedora19.box'
    end
  end

  config.vm.provider :libvirt do |domain|
    domain.memory = 2560
    domain.cpus = 2
  end

end

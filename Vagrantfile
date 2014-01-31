VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "centos" do |centos|
    centos.vm.box = "centos64"
    centos.vm.hostname = "centos.installer"

    centos.vm.provision :shell do |shell|
      shell.path = 'bootstrap-centos.sh'
      shell.args = "'/vagrant'"
    end
  end

  config.vm.provider :libvirt do |domain|
    domain.memory = 1536
    domain.cpus = 2
  end

end

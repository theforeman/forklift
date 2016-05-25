require 'test_helper'

class TestInstaller < Minitest::Test

  def setup
    @installer = Forklift::Installer.new
  end

  def test_run_installer
    @installer.expects(:syscall).with('foreman-installer --scenario foreman ').returns(true)

    assert @installer.run_installer('foreman-installer --scenario foreman')
  end

  def test_skip_installer
    @installer = Forklift::Installer.new(:skip_installer => true)
    @installer.expects(:system).with('katello-installer').never
    assert @installer.run_installer('katello-installer')
  end

  def test_install
    @installer.expects(:install_puppet)
    @installer.expects(:system).with('yum -y install foreman-installer')
    @installer.expects(:system).with('yum -y update')
    @installer.expects(:run_installer).with('foreman-installer --scenario foreman').returns(true)

    assert @installer.setup
    assert @installer.install
  end

  def test_install_katello
    @installer = Forklift::Installer.new(:scenario => 'katello')
    @installer.expects(:install_puppet)
    @installer.expects(:system).with('yum -y install katello')
    @installer.expects(:system).with('yum -y update')
    @installer.expects(:run_installer).with('foreman-installer --scenario katello').returns(true)

    assert @installer.setup
    assert @installer.install
  end

  def test_install_devel
    @installer = Forklift::Installer.new(:scenario => 'katello-devel')
    @installer.expects(:install_puppet)
    @installer.expects(:system).with('yum -y update')
    @installer.expects(:system).with('yum -y install foreman-installer-katello-devel')
    @installer.expects(:run_installer).with('foreman-installer --scenario katello-devel').returns(true)

    assert @installer.setup
    assert @installer.install
  end

end

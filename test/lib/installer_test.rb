require 'test_helper'

class TestInstaller < Minitest::Test

  def setup
    @installer = KatelloDeploy::Installer.new
  end

  def test_run_installer
    @installer.expects(:syscall).with('katello-installer ').returns(true)

    assert @installer.run_installer('katello-installer')
  end

  def test_skip_installer
    @installer = KatelloDeploy::Installer.new(:skip_installer => true)
    @installer.expects(:syscall).with('katello-installer').never
    assert @installer.run_installer('katello-installer')
  end

  def test_install
    @installer.expects(:install_puppet)
    @installer.expects(:system).with('yum -y install katello')
    @installer.expects(:run_installer).with('katello-installer').returns(true)

    assert @installer.install
  end

  def test_install_devel
    @installer = KatelloDeploy::Installer.new(:type => 'devel')
    @installer.expects(:install_puppet)
    @installer.expects(:system).with('yum -y install katello-devel-installer')
    @installer.expects(:run_installer).with('katello-devel-installer').returns(true)

    assert @installer.install
  end

  def test_install_sam
    @installer = KatelloDeploy::Installer.new(:type => 'sam')
    @installer.expects(:install_puppet)
    @installer.expects(:system).with('yum -y install katello-sam')
    @installer.expects(:run_installer).with('sam-installer').returns(true)

    assert @installer.install
  end

end

require 'test_helper'

class TestInstallerOptionsProcessor < Minitest::Test

  def setup
    @installer_options = '--foreman-password="changeme"'
  end

  def test_process
    installer_options = Forklift::Processors::InstallerOptionsProcessor.process(
      :installer_options => @installer_options
    )
    assert_equal installer_options, @installer_options
  end

  def test_process_devel_user
    installer_options = Forklift::Processors::InstallerOptionsProcessor.process(
      :installer_options => @installer_options,
      :devel_user => 'testuser'
    )
    @installer_options = "#{@installer_options} --katello-devel-user=testuser"\
        ' --certs-group=testuser --katello-deployment-dir=/home/testuser --disable-system-checks'

    assert_equal installer_options, @installer_options
  end

end

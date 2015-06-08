require 'test_helper'

class TestInstallerOptionsProcessor < Minitest::Test

  def setup
    @installer_options = '--foreman-password="changeme"'
  end

  def test_process
    installer_options = KatelloDeploy::Processors::InstallerOptionsProcessor.process(
      :installer_options => @installer_options
    )
    assert_equal installer_options, @installer_options
  end

  def test_process_devel_user
    installer_options = KatelloDeploy::Processors::InstallerOptionsProcessor.process(
      :installer_options => @installer_options,
      :devel_user => 'testuser'
    )
    @installer_options = "#{@installer_options} --user=testuser --group=testuser --deployment-dir=/home/testuser"

    assert_equal installer_options, @installer_options
  end

end

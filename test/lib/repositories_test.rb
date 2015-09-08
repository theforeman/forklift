require 'test_helper'

class TestRepositories < Minitest::Test

  def setup
    @repo = KatelloDeploy::Repositories.new(:katello_version => '2.3',
                                            :distro          => 'rhel',
                                            :os_version      => 7)
  end

  def test_bootstrap_foreman_release
    @repo.expects(:local_install).with('http://yum.theforeman.org/releases/1.9/el7/x86_64/foreman-release.rpm')
    @repo.bootstrap_foreman('1.9', 7)
  end

  def test_bootstrap_foreman_nightly
    @repo.expects(:local_install).with('http://yum.theforeman.org/nightly/el7/x86_64/foreman-release.rpm')
    @repo.bootstrap_foreman('nightly', 7)
  end

end

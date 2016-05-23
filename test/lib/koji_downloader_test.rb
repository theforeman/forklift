require 'test_helper'

class TestKojiDownloader < Minitest::Test

  def setup
    @downloader = Forklift::KojiDownloader.new(
      :task_id => '215467',
      :directory => '/tmp/fake_repo'
    )
  end

  def koji_fixture
    File.read('test/fixtures/koji_build_page.html')
  end

  def test_download
    @downloader.expects(:build_info).returns(koji_fixture)
    File.expects(:open)
        .with('/tmp/fake_repo/ruby193-rubygem-katello-2.3.0-1.201505070058git30746ed.el7.noarch.rpm', 'wb')
    File.expects(:open)
        .with('/tmp/fake_repo/ruby193-rubygem-katello-2.3.0-1.201505070058git30746ed.el7.src.rpm', 'wb')

    assert @downloader.download
  end

end

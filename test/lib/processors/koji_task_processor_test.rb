require 'test_helper'

class TestKojiTaskProcessor < Minitest::Test

  def test_process_empty_tasks
    refute KatelloDeploy::Processors::KojiTaskProcessor.process([])
  end

  def test_process
    KatelloDeploy::KojiDownloader.any_instance.expects(:download)
    KatelloDeploy::RepoMaker.any_instance.expects(:create)

    KatelloDeploy::Processors::KojiTaskProcessor.process(['213456'])
  end

end

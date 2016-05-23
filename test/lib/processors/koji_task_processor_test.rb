require 'test_helper'

class TestKojiTaskProcessor < Minitest::Test

  def test_process_empty_tasks
    refute Forklift::Processors::KojiTaskProcessor.process([])
  end

  def test_process
    Forklift::KojiDownloader.any_instance.expects(:download)
    Forklift::RepoMaker.any_instance.expects(:create)

    Forklift::Processors::KojiTaskProcessor.process(['213456'])
  end

end

require 'test_helper'

class TestScriptsProcessor < Minitest::Test

  def test_process
    scripts_mock = mock

    File.expects(:directory?).with('scripts').returns(true)
    Dir.expects(:chdir).yields(KatelloDeploy::Processors::ScriptsProcessor.run_scripts)
    Dir.expects(:glob).with('*').returns(scripts_mock)
    scripts_mock.expects(:select).returns(['test.sh'])
    KatelloDeploy::Processors::ScriptsProcessor.expects(:system).with('./test.sh')

    assert KatelloDeploy::Processors::ScriptsProcessor.process
  end

  def test_process_no_directory
    File.expects(:directory?).with('scripts').returns(false)

    refute KatelloDeploy::Processors::ScriptsProcessor.process
  end

end

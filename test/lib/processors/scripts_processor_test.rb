require 'test_helper'

class TestScriptsProcessor < Minitest::Test

  def test_process
    File.expects(:directory?).with('scripts').returns(true)
    Dir.expects(:chdir)

    assert Forklift::Processors::ScriptsProcessor.process
  end

  def test_run_scripts
    scripts_mock = mock
    scripts_mock.expects(:select).returns(['test.sh'])

    Dir.expects(:glob).with('*').returns(scripts_mock)
    Forklift::Processors::ScriptsProcessor.expects(:system).with('./test.sh')

    assert Forklift::Processors::ScriptsProcessor.run_scripts
  end

  def test_process_no_directory
    File.expects(:directory?).with('scripts').returns(false)

    refute Forklift::Processors::ScriptsProcessor.process
  end

end

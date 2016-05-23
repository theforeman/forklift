require 'test_helper'

class TestModulePullRequestProcessor < Minitest::Test

  def test_process
    Forklift::ModulePullRequest.any_instance.expects(:prepare).returns(true)
    Forklift::ModulePullRequest.any_instance.expects(:setup_pull_request).with('qpid', '44')

    assert Forklift::Processors::ModulePullRequestProcessor.process(['qpid/44'], :base_path => '/tmp')
  end

end

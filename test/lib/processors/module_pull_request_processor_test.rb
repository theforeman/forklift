require 'test_helper'

class TestModulePullRequestProcessor < Minitest::Test

  def test_process
    KatelloDeploy::ModulePullRequest.any_instance.expects(:prepare).returns(true)
    KatelloDeploy::ModulePullRequest.any_instance.expects(:setup_pull_request).with('qpid', '44')

    assert KatelloDeploy::Processors::ModulePullRequestProcessor.process(['qpid/44'], :base_path => '/tmp')
  end

end

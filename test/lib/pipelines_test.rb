require 'test_helper'

class TestPipelines < Minitest::Test

  def setup
    @pipeline_loader = Forklift::PipelineLoader.new('test/fixtures/pipelines')
  end

  def test_load
    assert @pipeline_loader.load
    assert_equal 1, @pipeline_loader.pipelines.length
    assert_equal 2, @pipeline_loader.pipelines.first['boxes'].length
  end

end

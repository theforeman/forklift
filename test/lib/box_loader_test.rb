require 'test_helper'

class TestBoxLoader < Minitest::Test

  def setup
    @box_loader = Forklift::BoxLoader.new
  end

  def test_load
    assert @pipeline_loader.load
  end

end

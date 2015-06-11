require 'test_helper'

class TestBoxLoader < Minitest::Test

  def setup
    @box_loader = KatelloDeploy::BoxLoader.new
  end

  def test_load
    assert @box_loader.add_boxes('config/base_boxes.yaml')
  end

  def test_centos6
    boxes = @box_loader.add_boxes('config/base_boxes.yaml')
    assert_equal 'centos6-nightly', boxes['centos6-nightly']['name']
    assert_equal 'centos6', boxes['centos6-nightly']['box_name']
  end

end

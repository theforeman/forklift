require 'test_helper'

class TestBoxLoader < Minitest::Test

  def setup
    @box_loader = Forklift::BoxLoader.new
  end

  def test_load
    assert @box_loader.add_boxes('config/base_boxes.yaml', 'config/versions.yaml')
  end

  def test_centos6
    boxes = @box_loader.add_boxes('config/base_boxes.yaml', 'config/versions.yaml')
    assert_equal 'centos6-katello-nightly', boxes['centos6-katello-nightly']['name']
    assert_equal 'centos6', boxes['centos6-katello-nightly']['box_name']
  end

end

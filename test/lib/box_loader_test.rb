require 'test_helper'

class TestBoxLoader < Minitest::Test

  def setup
    @box_loader = Forklift::BoxLoader.new
  end

  def test_load
    assert @box_loader.add_boxes('config/base_boxes.yaml', 'config/versions.yaml')
  end

  def test_centos7
    boxes = @box_loader.add_boxes('config/base_boxes.yaml', 'config/versions.yaml')
    assert_equal 'centos7-katello-nightly', boxes['centos7-katello-nightly']['name']
    assert_equal 'centos/7', boxes['centos7-katello-nightly']['box_name']
  end

end

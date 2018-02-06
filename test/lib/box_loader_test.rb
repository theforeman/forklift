require 'test_helper'

class TestBoxLoader < Minitest::Test

  def test_load
    locations = get_locations('00-base.yaml')
    loader = Forklift::BoxLoader.new(nil, locations)
    loader.load!

    assert loader.boxes
    assert_equal 'centos7-katello-nightly', loader.boxes['centos7-katello-nightly']['name']
    assert_equal 'centos/7', loader.boxes['centos7-katello-nightly']['box_name']
  end

  private

  def get_locations(*filenames)
    filenames.map { |name| File.join(root_dir, 'boxes.d', name) }
  end

  def root_dir
    File.dirname(File.dirname(File.dirname(__FILE__)))
  end

end

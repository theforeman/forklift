# frozen_string_literal: true

require 'test_helper'

class TestBoxLoader < Minitest::Test

  def test_load
    locations = get_locations('00-centos.yaml')
    loader = Forklift::BoxLoader.new(nil, locations)
    loader.load!

    assert_instance_of Hash, loader.boxes
    assert_includes loader.boxes, 'centos8-stream-katello-nightly'
    assert_equal 'centos8-stream-katello-nightly', loader.boxes['centos8-stream-katello-nightly']['name']
    assert_equal 'centos/stream8', loader.boxes['centos8-stream-katello-nightly']['box_name']
  end

  def test_load_with_exclude
    excludes = { 'boxes' => { 'exclude' => ['fedora'] } }
    Forklift::Settings.any_instance.stubs(:settings).returns(excludes)
    locations = get_locations('00-fedora.yaml', '03-packaging.yaml')
    loader = Forklift::BoxLoader.new(nil, locations)
    loader.load!

    assert_instance_of Hash, loader.boxes
    assert_includes loader.boxes, 'rpm-packaging'
    assert_equal 'rpm-packaging', loader.boxes['rpm-packaging']['name']
    assert_equal 'fedora/33-cloud-base', loader.boxes['rpm-packaging']['box_name']
  end

  private

  def get_locations(*filenames)
    filenames.map { |name| File.join(root_dir, 'boxes.d', name) }
  end

  def root_dir
    File.dirname(File.dirname(File.dirname(__FILE__)))
  end

end

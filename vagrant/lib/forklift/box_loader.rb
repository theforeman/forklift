module Forklift
  class BoxLoader

    attr_reader :boxes

    def initialize
      @box_factory = BoxFactory.new
      @root_dir = "#{File.dirname(__FILE__)}/../../"
      @boxes = {}
    end

    def load
      add_base_boxes
      plugin_vagrantfiles
      add_plugin_base_boxes
      add_user_boxes
    end

    def add_base_boxes
      @boxes = @box_factory.add_boxes("#{@root_dir}/config/base_boxes.yaml", "#{@root_dir}/config/versions.yaml")
    end

    def add_user_boxes
      return unless File.exist?("#{@root_dir}/boxes.yaml")
      @boxes = @box_factory.add_boxes("#{@root_dir}/boxes.yaml", "#{@root_dir}/config/versions.yaml")
    end

    def add_boxes(boxes)
      @boxes = @box_factory.add_boxes(boxes, "#{@root_dir}/config/versions.yaml")
    end

    def boxes
      box_files = Dir.glob "#{Dir.pwd}/.tmp_boxes/*.yaml"
      box_files.each { |tmp_boxes| add_boxes(tmp_boxes) }
      @boxes
    end

    def add_plugin_base_boxes
      base_boxes = Dir.glob "#{@root_dir}/plugins/*/base_boxes.yaml"
      base_boxes.each { |boxes| add_boxes(boxes) }
    end

    def plugin_vagrantfiles
      Dir.glob "#{@root_dir}/plugins/*/Vagrantfile"
    end

  end
end

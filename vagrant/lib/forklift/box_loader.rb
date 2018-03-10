module Forklift
  class BoxLoader

    attr_accessor :locations

    def initialize(root_dir = nil, locations = nil)
      @root_dir = root_dir || default_root_dir
      @locations = locations || default_locations
      @box_factory = BoxFactory.new(versions)
    end

    def load!
      @locations.sort_by { |f| File.basename(f) }.each do |box_file|
        @box_factory.add_boxes!(box_file)
      end
    end

    def boxes
      @box_factory.boxes
    end

    private

    def default_root_dir
      "#{File.dirname(__FILE__)}/../../"
    end

    def default_locations
      Dir.glob(["#{@root_dir}/boxes.d/*.yaml", "#{@root_dir}/plugins/*/base_boxes.yaml"])
    end

    def versions
      YAML.load_file("#{@root_dir}/config/versions.yaml")
    end

  end
end

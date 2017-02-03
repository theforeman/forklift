require 'yaml'

module Forklift
  class PipelineLoader

    attr_reader :pipelines_directory, :pipelines

    def initialize(pipelines_directory = nil)
      @pipelines_directory = pipelines_directory || "pipelines"
      @pipelines = []
      load_pipelines
    end

    def load_pipelines
      files = Dir.glob("#{@pipelines_directory}/**/pipeline.yaml")
      @pipelines = files.collect do |file|
        data = YAML.load_file(file)
        data['location'] = File.dirname(file)
        OpenStruct.new(data)
      end
    end

    def pipeline(name)
      @pipelines.find { |pipeline| pipeline.name == name }
    end

    def boxes
      @pipelines.collect { |pipeline| pipeline.boxes }
    end

  end
end

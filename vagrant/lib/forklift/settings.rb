# frozen_string_literal: true

module Forklift
  class Settings

    attr_reader :settings

    def initialize
      settings_file = File.join(__dir__, '..', '..', 'settings.yaml')
      @settings = if File.exist?(settings_file)
                    if Gem::Version.new(Psych::VERSION) < Gem::Version.new('4.0')
                      YAML.safe_load(File.read(settings_file), [:Symbol])
                    else
                      YAML.safe_load(File.read(settings_file), permitted_classes: [:Symbol])
                    end
                  else
                    {}
                  end
    end

  end
end

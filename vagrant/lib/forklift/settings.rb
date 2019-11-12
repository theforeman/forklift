# frozen_string_literal: true

module Forklift
  class Settings

    attr_reader :settings

    def initialize
      settings_file = File.join(__dir__, '..', '..', 'settings.yaml')
      @settings = File.exist?(settings_file) ? YAML.load_file(settings_file) : {}
    end

  end
end

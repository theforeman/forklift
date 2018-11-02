require 'json'
require 'erb'
require 'yaml'

require_relative 'compat'

module Forklift
  class BoxFactory

    attr_accessor :boxes

    def initialize(versions)
      @versions = versions
      @boxes = {}
    end

    def add_boxes!(box_file)
      config = load_box_file(box_file)
      return unless config

      if config.key?('boxes')
        process_versions(config)
        process_boxes!(config['boxes'])
      else
        process_boxes!(config)
      end
    end

    private

    def load_box_file(file)
      file = File.read(file)
      YAML.load(ERB.new(file).result)
    end

    def process_boxes!(boxes)
      boxes.each do |name, box|
        box['name'] = name
        box = layer_base_box(box)

        if @boxes[name]
          @boxes[name].deep_merge!(box)
        else
          @boxes[name] = box
        end
      end
    end

    def process_versions(config)
      @versions['installers'].each do |version|
        version['boxes'].each do |base_box|
          next unless config['boxes'].key?(base_box)

          scenarios = config['boxes'][base_box]['scenarios'] || []
          scenarios.each do |scenario|
            installer_box = build_box(config['boxes'][base_box], 'server', "playbooks/#{scenario}.yml", version)
            config['boxes']["#{base_box}-#{scenario}-#{version[scenario]}"] = installer_box
          end

          next unless scenarios.include?('katello')

          foreman_proxy_box = build_box(config['boxes'][base_box], 'foreman-proxy-content',
                                        'playbooks/foreman_proxy_content.yml', version)
          foreman_proxy_box['ansible']['server'] = "#{base_box}-katello-#{version['katello']}"
          config['boxes']["#{base_box}-foreman-proxy-#{version['katello']}"] = foreman_proxy_box
        end
      end
    end

    def layer_base_box(box)
      return box unless (base_box = find_base_box(box['box']))

      deep_merge(base_box, box)
    end

    def find_base_box(name)
      return false if name.nil?

      @boxes[name]
    end

    def build_box(base_box, group, playbook, version)
      box = JSON.parse(JSON.dump(base_box))

      variables = {}
      variables.merge!(box['ansible']['variables']) if box['ansible'] && box['ansible']['variables']
      variables.merge!(
        'foreman_repositories_version' => version['foreman'],
        'katello_repositories_version' => version['katello'],
        'puppet_repositories_version' => version['puppet']
      )

      box['ansible'] = {
        'playbook' => playbook,
        'group' => group,
        'variables' => variables
      }

      box
    end

  end
end

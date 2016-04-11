module KatelloDeploy
  class BoxLoader

    attr_accessor :boxes, :shells

    def initialize
      @boxes = {}
      @shells = {}
    end

    def add_boxes(box_file, version_file)
      config = YAML.load_file(box_file)
      return @boxes unless config

      versions = YAML.load_file(version_file)

      process_shells(config['shells']) if config.key?('shells')

      if config.key?('boxes')
        process_versions(config, versions)
        process_boxes(config['boxes'])
      else
        process_boxes(config)
      end

      @boxes
    end

    private

    def process_shells(shells)
      @shells.merge!(shells)
    end

    def process_boxes(boxes)
      boxes.each do |name, box|
        box['name'] = name
        box = layer_base_box(box)
        box['shell'] += " #{box['options']} " if box['shell'] && box['options']
        box['shell'] += " --installer-options='#{box['installer']}' " if box['shell'] && box['installer']

        if @boxes[name]
          @boxes[name].merge!(box)
        else
          @boxes[name] = box
        end
      end

      @boxes
    end

    def process_versions(config, versions)
      versions['foreman'].each do |version|
        config['boxes']["centos6-foreman-#{version}"] = Marshal.load(
          Marshal.dump(config['boxes']['centos6-foreman-nightly'])
        )
        config['boxes']["centos6-foreman-#{version}"]['options'] << " --version #{version}"

        next unless (katello_version = versions['mapping'][version])

        config['boxes']["centos6-katello-#{katello_version}"] = Marshal.load(
          Marshal.dump(config['boxes']['centos6-katello-nightly'])
        )
        config['boxes']["centos6-katello-#{katello_version}"]['options'] << " --version #{version}"
      end

      versions['foreman'].each do |version|
        config['boxes']["centos7-foreman-#{version}"] = Marshal.load(
          Marshal.dump(config['boxes']['centos7-foreman-nightly'])
        )
        config['boxes']["centos7-foreman-#{version}"]['options'] << " --version #{version}"

        next unless (katello_version = versions['mapping'][version])

        config['boxes']["centos7-katello-#{katello_version}"] = Marshal.load(
          Marshal.dump(config['boxes']['centos7-katello-nightly'])
        )
        config['boxes']["centos7-katello-#{katello_version}"]['options'] << " --version #{version}"
      end
    end

    def layer_base_box(box)
      return box unless (base_box = find_base_box(box['box']))
      base_box.merge(box)
    end

    def find_base_box(name)
      return false if name.nil?
      @boxes[name]
    end

  end
end

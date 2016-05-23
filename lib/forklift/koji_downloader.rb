require 'open-uri'

module Forklift
  class KojiDownloader

    attr_reader :task_id, :directory

    def initialize(args)
      @task_id = args.fetch(:task_id)
      @directory = args.fetch(:directory)
    end

    def download
      puts 'Starting Koji package download'

      Dir.mkdir(@directory) unless File.exist?(@directory)

      packages_in_build.each do |package|
        download_scratch_build(package, @directory)
      end
    end

    private

    def koji_url
      'http://koji.katello.org'
    end

    def packages_in_build
      puts "Finding packages for Task: #{@task_id}"
      info = build_info
      info.scan(/href=".*.rpm"/).collect { |link| link.split('name=')[1].delete('"') }
    end

    def build_info
      get("#{koji_url}/koji/taskinfo?taskID=#{task_id}")
    end

    def download_scratch_build(package, directory)
      puts "Downloading #{package} to #{directory}"
      File.open("#{directory}/#{package}", 'wb') do |file|
        file << get("#{koji_url}/koji/getfile?taskID=#{@task_id}&name=#{package}")
      end
    end

    def get(uri)
      open(uri).read
    end

  end
end

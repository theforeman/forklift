require 'open-uri'


class KojiDownloader

  attr_reader :task_id, :directory

  KOJI_URL = "http://koji.katello.org"

  def initialize(args)
    @task_id = args.fetch(:task_id)
    @directory = args.fetch(:directory)
  end

  def download
    puts "Starting Koji package download"

    if !File.exist?(@directory)
      Dir.mkdir(@directory)
    end

    packages_in_build.each do |package|
      download_scratch_build(package, @directory)
    end
  end

  private

  def packages_in_build
    puts "Finding packages for Task: #{@task_id}"
    info = build_info
    info.scan(/href=".*.rpm"/).collect { |link| link.split('name=')[1].gsub('"', '') }
  end

  def build_info
    open("#{KOJI_URL}/koji/taskinfo?taskID=#{task_id}").read
  end

  def download_scratch_build(package, directory)
    puts "Downloading #{package} to #{directory}"
    File.open("#{directory}/#{package}", 'wb') do |file|
      file << open("#{KOJI_URL}/koji/getfile?taskID=#{@task_id}&name=#{package}").read
    end
  end

end

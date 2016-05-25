module Forklift
  class RepoFile

    attr_accessor :name, :baseurl, :enabled, :gpgcheck, :protect, :priority

    def initialize(args)
      @name = args.fetch(:name)
      @baseurl = args.fetch(:baseurl)
      @enabled = args.fetch(:enabled, 1)
      @gpgcheck = args.fetch(:gpgcheck, 0)
      @protect = args.fetch(:protect, 1)
      @priority = args.fetch(:priority, nil)
    end

    def deploy
      puts 'Deploying local repo file'
      write_repo_file(repo_file)
    end

    def cleanup
      return unless File.exist?(repo_file_path)
      File.delete(repo_file_path)
    end

    def repo_file
      repo = "[#{hyphen_name}]\n" \
             "name=Repository for #{@name}\n" \
             "baseurl=#{@baseurl}\n" \
             "enabled=#{@enabled}\n" \
             "gpgcheck=#{@gpgcheck}\n" \
             "protect=#{@protect}"

      repo += "\npriority=#{@priority}" unless @priority.nil?
      repo
    end

    private

    def write_repo_file(repo)
      File.open(repo_file_path, 'w') { |file| file.write(repo) }
    end

    def repo_file_path
      "/etc/yum.repos.d/#{hyphen_name}.repo"
    end

    def hyphen_name
      @name.downcase.split(' ').join('-')
    end

  end
end

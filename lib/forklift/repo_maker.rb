require 'forklift/repo_file'

module Forklift
  class RepoMaker

    attr_reader :name, :priority

    def initialize(args)
      @name = args.fetch(:name)
      @directory = args.fetch(:directory)
      @priority = args.fetch(:priority, nil)
      @repo_file = RepoFile.new(
        :name     => @name,
        :baseurl  => "file://#{File.expand_path(@directory)}",
        :priority => @priority
      )
    end

    def create
      @repo_file.cleanup
      install_createrepo
      create_repo
      @repo_file.deploy
    end

    private

    def syscall(command)
      system(command)
    end

    def create_repo
      puts "Running createrepo on #{@directory}"
      syscall("createrepo #{@directory}")
      syscall("chmod -R o-w+r #{@directory}")
    end

    def install_createrepo
      return if syscall('rpm -q createrepo')
      puts 'Installing createrepo'
      syscall('yum -y install createrepo')
    end

  end
end

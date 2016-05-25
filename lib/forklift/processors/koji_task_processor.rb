require 'forklift/koji_downloader'
require 'forklift/repo_maker'

module Forklift
  module Processors
    module KojiTaskProcessor
      def self.process(koji_tasks = [])
        return false if koji_tasks.empty?

        koji_tasks.each do |task|
          downloader = Forklift::KojiDownloader.new(:task_id => task, :directory => './repo')
          downloader.download
        end

        repo_maker = Forklift::RepoMaker.new(
          :name => "Koji Scratch Repo for #{koji_tasks.join(' ')}",
          :directory => './repo',
          :priority => 1
        )

        repo_maker.create
      end
    end
  end
end

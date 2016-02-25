require 'katello_deploy/koji_downloader'
require 'katello_deploy/repo_maker'

module KatelloDeploy
  module Processors
    module KojiTaskProcessor
      def self.process(koji_tasks = [])
        return false if koji_tasks.empty?

        koji_tasks.each do |task|
          downloader = KatelloDeploy::KojiDownloader.new(:task_id => task, :directory => './repo')
          downloader.download
        end

        repo_maker = KatelloDeploy::RepoMaker.new(
          :name => "Koji Scratch Repo for #{koji_tasks.join(' ')}",
          :directory => './repo',
          :priority => 1
        )

        repo_maker.create
      end
    end
  end
end

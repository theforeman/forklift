require 'clamp'

module Forklift
  module Command
    class LocalRepoCommand < Clamp::Command

      option "--name", "NAME", "Name for the local repository", :required => true
      option "--path", "PATH", "Path to directory to turn into a local repository", :required => true
      option "--priority", "PRIORITY", "Optionally specify the repositories priority"

      def execute
        repo_maker = Forklift::RepoMaker.new(
          :name => @name,
          :directory => @path,
          :priority => @priority,
        )

        repo_maker.create
      end

    end
  end
end

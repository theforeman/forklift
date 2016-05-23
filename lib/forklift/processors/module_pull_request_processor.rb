require 'forklift/koji_downloader'
require 'forklift/repo_maker'

module Forklift
  module Processors
    module ModulePullRequestProcessor
      def self.process(module_prs = [], base_path = '/')
        return false if module_prs.empty?

        module_pr = Forklift::ModulePullRequest.new(:base_path => base_path)
        prepared = module_pr.prepare

        return false unless prepared

        module_prs.each do |pr|
          module_pr.setup_pull_request(pr.split('/')[0], pr.split('/')[1])
        end

        true
      end
    end
  end
end

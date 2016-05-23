module Forklift
  class ModulePullRequest

    attr_reader :puppetfile, :base_path

    def initialize(args)
      @base_path = args.fetch(:base_path)
    end

    def prepare
      install_git
      clone_installer
      read_puppetfile
      true
    end

    def setup_pull_request(puppet_module, pr_number)
      git_url = find_git_url(puppet_module)

      if git_url
        Dir.chdir("#{installer_path}/modules") do
          system("rm -rf #{puppet_module}")
          system("git clone #{git_url} #{puppet_module}")

          Dir.chdir(puppet_module) do
            system("git fetch origin pull/#{pr_number}/head:pr/#{pr_number}")
            system("git checkout pr/#{pr_number}")
          end
        end
        true
      else
        puts "Unable to find git url within Puppetfile for #{puppet_module}"
        false
      end
    end

    def clone_installer
      return true unless File.exist?('katello-installer')
      `git clone https://github.com/katello/katello-installer.git`
    end

    def read_puppetfile
      Dir.chdir('katello-installer') do
        @puppetfile = File.read('Puppetfile')
      end
    end

    def find_git_url(puppet_module)
      split = @puppetfile.split("\n")
      entry = split.select { |item| item.to_s =~ /\-#{puppet_module}/ }[0]
      entry.split(',')[1].split('git => ')[1]
    end

    def install_git
      return true if system('rpm -q git')
      system('yum -y install git')
    end

    def bundle_install
      system('yum -y install rubygem-bundler ruby-devel ruby')
      system('bundle install')
    end

    def installer_path
      '/usr/share/katello-installer-base'
    end

  end
end

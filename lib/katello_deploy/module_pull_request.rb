module KatelloDeploy
  class ModulePullRequest

    attr_reader :puppetfile, :base_path

    def initialize(args)
      @base_path = args.fetch(:base_path)
    end

    def prepare
      install_git
      setup_katello_installer
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

    def setup_katello_installer
      if local_installer_exists?
        Dir.chdir(installer_path) do
          system('git fetch origin')
          system('git checkout origin/master')
        end
      else
        Dir.chdir(@base_path) do
          system('git clone https://github.com/Katello/katello-installer.git')
        end
      end
    end

    def local_installer_exists?
      File.exist?(installer_path)
    end

    def read_puppetfile
      Dir.chdir(installer_path) do
        @puppetfile = File.read('Puppetfile')
      end
    end

    def find_git_url(puppet_module)
      split = @puppetfile.split("\n")
      entry = split.select { |item| item.to_s =~ /#{puppet_module}/ }[0]
      entry.split(',')[1].split('git => ')[1]
    end

    def install_git
      return if system('rpm -q git')
      system('yum -y install git')
    end

    def installer_path
      "#{@base_path}/katello-installer"
    end

  end
end

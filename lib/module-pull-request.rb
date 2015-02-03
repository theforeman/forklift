class ModulePullRequest

  attr_reader :puppetfile

  def initialize
    setup_katello_installer
    install_git
    read_puppetfile
  end

  def setup_pull_request(puppet_module, pr_number)
    git_url = find_git_url(puppet_module)

    if git_url
      Dir.chdir('./katello-installer/modules') do
        system("rm -rf #{puppet_module}")
        system("git clone #{git_url} #{puppet_module}")

        Dir.chdir(puppet_module) do
          system("git fetch origin pull/#{pr_number}/head:pr/#{pr_number}")
          system("git checkout pr/#{pr_number}")
        end
      end
    else
      puts "Unable to find git url within Puppetfile for #{puppet_module}"
    end
  end

  def setup_katello_installer
    if local_installer_exists?
      Dir.chdir('./katello-installer') do
        system('git fetch origin')
        system('git checkout origin/master')
      end
    else
      system('git clone https://github.com/Katello/katello-installer.git')
    end
  end

  def local_installer_exists?
    File.exist?('./katello-installer')
  end

  def read_puppetfile
    Dir.chdir('./katello-installer') do
      @puppetfile = File.read('Puppetfile')
    end
  end

  def find_git_url(puppet_module)
    split = @puppetfile.split("\n")
    entry = split.select { |item| item.to_s =~ /#{puppet_module}/ }[0]
    entry.split(',')[1].split('git => ')[1]
  end

  def install_git
    if !system('rpm -q git')
      system('yum -y install git')
    end
  end

end

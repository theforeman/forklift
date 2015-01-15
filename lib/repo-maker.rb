class RepoMaker

  attr_reader :name

  def initialize(args)
    @name = args.fetch(:name)
    @directory = args.fetch(:directory)
  end

  def create
    cleanup_repo_file
    install_createrepo

    puts "Running createrepo on #{@directory}"
    system("createrepo #{@directory}")
    system("chmod -R o-w+r #{@directory}")

    deploy_repo_file
  end

  private

  def cleanup_repo_file
    if File.exist?(repo_file)
      File.delete(repo_file)
    end
  end

  def install_createrepo
    installed = system('rpm -q createrepo')

    puts installed
    if !installed
      puts "Installing createrepo"
      system('yum -y install createrepo')
    end
  end

  def deploy_repo_file
    puts "Deploying local repo file"

    repo = "[#{hyphen_name}]\n" \
           "name=Local repository for #{@name}\n" \
           "baseurl=file://#{File.expand_path(@directory)}\n" \
           "enabled=1\n" \
           "gpgcheck=0\n" \
           "protect=1"

    File.open(repo_file, 'w') { |file| file.write(repo) }
  end

  def hyphen_name
    @name.downcase.split(' ').join('-')
  end

  def repo_file
    "/etc/yum.repos.d/#{hyphen_name}.repo"
  end

end

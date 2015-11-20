require 'yaml'
require 'katello_deploy/repo_file'

module KatelloDeploy
  class Repositories

    attr_reader :os_version, :distro

    def initialize(args)
      @katello_version = args.fetch(:katello_version)
      @os_version = args.fetch(:os_version)
      @distro = args.fetch(:distro)
      @versions = YAML.load_file('config/versions.yaml')
    end

    def configure(koji_repos = false)
      cleanup
      configure_rhel(@os_version) if @distro == 'rhel'
      bootstrap_epel(@os_version)
      bootstrap_puppet(@os_version)

      if koji_repos
        setup_koji_repos(@os_version, @katello_version, foreman_version)
      else
        bootstrap_katello(@katello_version, @os_version)
        bootstrap_foreman(foreman_version, @os_version)
      end
      bootstrap_scl
      true
    end

    def foreman_version
      @versions[@katello_version]
    end

    def cleanup
      system('yum clean all')
      system('yum -y update nss ca-certificates')
      system('rpm -e epel-release')
      system('rpm -e foreman-release')
      system('rpm -e katello-repos')
      system('rpm -e puppetlabs-release')
    end

    def configure_rhel(os_version)
      # Setup RHEL specific repos
      system("yum -y  --disablerepo=\"*\" --enablerepo=rhel-#{os_version}-server-rpms install yum-utils wget")
      system('yum repolist') # TODO: necessary?
      system('yum-config-manager --disable "*"')
      system('yum-config-manager --enable epel')
      system(
        "subscription-manager repos --enable rhel-#{os_version}-server-rpms " \
        "--enable rhel-#{os_version}-server-extras-rpms --enable rhel-#{os_version}-server-optional-rpms"
      )
      # As epel repo uses mirrorlist and yum vars.
      system('yum -y install yum-plugin-fastestmirror')
    end

    def bootstrap_epel(release)
      local_install("http://dl.fedoraproject.org/pub/epel/epel-release-latest-#{release}.noarch.rpm", false)
    end

    def bootstrap_scl
      install('foreman-release-scl')
    end

    def bootstrap_katello(version, os_version)
      local_install(
        'https://fedorapeople.org/groups/katello/releases/yum/' \
        "#{version}/katello/RHEL/#{os_version}/x86_64/katello-repos-latest.rpm"
      )
    end

    def bootstrap_foreman(version, os_version)
      local_install("http://yum.theforeman.org/#{version}/el#{os_version}/x86_64/foreman-release.rpm")
    end

    def bootstrap_puppet(os_version)
      local_install("http://yum.puppetlabs.com/puppetlabs-release-el-#{os_version}.noarch.rpm")
    end

    # rubocop:disable Metrics/MethodLength
    def setup_koji_repos(os, version = 'nightly', foreman_version = 'nightly')
      foreman_version = foreman_version.gsub('releases/', '')

      katello = KatelloDeploy::RepoFile.new(
        :name => 'katello_koji',
        :baseurl => "http://koji.katello.org/releases/yum/katello-#{version}/katello/RHEL/#{os}/x86_64/",
        :priority => 1
      )

      client = KatelloDeploy::RepoFile.new(
        :name => 'katello_client_koji',
        :baseurl => "http://koji.katello.org/releases/yum/katello-#{version}/client/RHEL/#{os}/x86_64/",
        :priority => 1
      )

      pulp = KatelloDeploy::RepoFile.new(
        :name => 'pulp_koji',
        :baseurl => "http://koji.katello.org/releases/yum/katello-#{version}/pulp/RHEL/#{os}/x86_64/",
        :priority => 1
      )

      candlepin = KatelloDeploy::RepoFile.new(
        :name => 'candlepin_koji',
        :baseurl => "http://koji.katello.org/releases/yum/katello-#{version}/candlepin/RHEL/#{os}/x86_64/",
        :priority => 1
      )

      foreman = KatelloDeploy::RepoFile.new(
        :name => 'foreman_koji',
        :baseurl => "http://koji.katello.org/releases/yum/foreman-#{foreman_version}/RHEL/#{os}/x86_64/"
      )

      plugins = KatelloDeploy::RepoFile.new(
        :name => 'foreman_plugins',
        :baseurl => "http://yum.theforeman.org/plugins/#{foreman_version}/el#{os}/x86_64/"
      )

      katello.deploy
      client.deploy
      pulp.deploy
      candlepin.deploy
      foreman.deploy
      plugins.deploy

      install('yum-plugin-priorities')
    end

    private

    def install(rpm)
      system("yum -y install #{rpm}")
    end

    def local_install(rpm, use_yum = true)
      if use_yum
        system("yum -y localinstall #{rpm}")
      else
        system("rpm -Uvh #{rpm}")
      end
    end

  end
end

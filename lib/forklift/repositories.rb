require 'yaml'
require 'forklift/repo_file'

module Forklift
  class Repositories

    attr_reader :os_version, :distro, :version, :scenario

    def initialize(args)
      @versions = YAML.load_file('config/versions.yaml')
      @version = args.fetch(:version, 'nightly').to_s
      @os_version = args.fetch(:os_version)
      @distro = args.fetch(:distro)
      @scenario = args.fetch(:scenario, 'foreman')
    end

    def configure(koji_repos = false)
      cleanup
      configure_rhel(@os_version) if @distro == 'rhel'
      bootstrap_epel(@os_version)
      bootstrap_puppet(@os_version)

      if koji_repos
        setup_foreman_koji_repos(@os_version, @version)
        setup_katello_koji_repos(@os_version, katello_version) if @scenario == 'katello' || @scenario == 'katello-devel'
      else
        bootstrap_foreman(@version, @os_version)
        bootstrap_katello(katello_version, @os_version) if @scenario == 'katello' || @scenario == 'katello-devel'
      end

      bootstrap_scl
      true
    end

    def katello_version
      @versions['mapping'][@version]
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
        "#{version}/katello/el#{os_version}/x86_64/katello-repos-latest.rpm"
      )
    end

    def bootstrap_foreman(version, os_version)
      version = (version == 'nightly') ? 'nightly' : "releases/#{version}"
      local_install("http://yum.theforeman.org/#{version}/el#{os_version}/x86_64/foreman-release.rpm")
    end

    def bootstrap_puppet(os_version)
      local_install("http://yum.puppetlabs.com/puppetlabs-release-el-#{os_version}.noarch.rpm")
    end

    def setup_foreman_koji_repos(os, version = 'nightly')
      version = version.gsub('releases/', '')

      foreman = Forklift::RepoFile.new(
        :name => 'foreman_koji',
        :baseurl => "http://koji.katello.org/releases/yum/foreman-#{version}/RHEL/#{os}/x86_64/"
      )

      plugins = Forklift::RepoFile.new(
        :name => 'foreman_plugins',
        :baseurl => "http://koji.katello.org/releases/yum/foreman-plugins-#{version}/RHEL/#{os}/x86_64/"
      )

      foreman.deploy
      plugins.deploy
    end

    def setup_katello_koji_repos(os, version = 'nightly')
      katello = Forklift::RepoFile.new(
        :name => 'katello_koji',
        :baseurl => "http://koji.katello.org/releases/yum/katello-#{version}/katello/el#{os}/x86_64/",
        :priority => 1
      )

      client = Forklift::RepoFile.new(
        :name => 'katello_client_koji',
        :baseurl => "http://koji.katello.org/releases/yum/katello-#{version}/client/el#{os}/x86_64/",
        :priority => 1
      )

      pulp = Forklift::RepoFile.new(
        :name => 'pulp_koji',
        :baseurl => "http://koji.katello.org/releases/yum/katello-#{version}/pulp/el#{os}/x86_64/",
        :priority => 1
      )

      candlepin = Forklift::RepoFile.new(
        :name => 'candlepin_koji',
        :baseurl => "http://koji.katello.org/releases/yum/katello-#{version}/candlepin/el#{os}/x86_64/",
        :priority => 1
      )

      katello.deploy
      client.deploy
      pulp.deploy
      candlepin.deploy

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

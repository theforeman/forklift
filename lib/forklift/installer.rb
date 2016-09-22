require 'yaml'
require 'English'
require 'fileutils'

module Forklift
  class Installer

    attr_accessor :installer_options, :skip_installer, :scenario, :root_dir, :installers, :puppet_four

    def initialize(args = {})
      self.installer_options = args.fetch(:installer_options, '')
      self.skip_installer = args.fetch(:skip_installer, false)
      self.scenario = args.fetch(:scenario, 'foreman')
      self.installers = YAML.load_file('config/installers.yaml')
      self.root_dir = args.fetch(:root_dir, '.')
      self.puppet_four = args.fetch(:puppet_four, false)
    end

    def setup
      install_puppet
      system('yum -y update')
      install_packages(@installers[@scenario.to_s]['packages'])
      setup_config
      true
    end

    def install
      run_installer(@installers[@scenario.to_s]['installer'])
    end

    def install_puppet
      if system('command -v gem >/dev/null 2>&1') && system('gem list | grep puppet > /dev/null')
        # Remove puppet gem to allow installing the package
        puts 'Uninstalling puppet gem'
        system('gem uninstall puppet')
        system('yum -y remove puppet')
        system('yum -y remove puppet-agent')
      end

      # ensure puppet is installed
      puppet_pkg = @puppet_four ? 'puppet-agent' : 'puppet'
      system("yum -y install #{puppet_pkg} && yum -y update #{puppet_pkg}")
    end

    def install_packages(packages)
      system("yum -y install #{packages.join(' ')}")
    end

    def setup_config
      return unless local_katello

      curr_dir = Dir.pwd

      if File.exist?("#{curr_dir}/katello-installer/modules")
        symlink(
          "#{curr_dir}/katello-installer/modules",
          '/usr/share/katello-installer-base/modules'
        )
      end

      symlink(
        "#{curr_dir}/katello-installer/config/katello-answers.yaml",
        "#{foreman_config_root}/katello-answers.yaml"
      )
      symlink(
        "#{curr_dir}/katello-installer/config/katello.migrations",
        "#{foreman_config_root}/katello.migrations"
      )

      symlink(
        "#{curr_dir}/katello-installer/config/katello-devel-answers.yaml",
        "#{foreman_config_root}/katello-devel-answers.yaml"
      )
      symlink(
        "#{curr_dir}/katello-installer/config/katello-devel.migrations",
        "#{foreman_config_root}/katello-devel.migrations"
      )
    end

    def run_installer(command)
      command = "./bin/#{command}" if local_foreman

      if @skip_installer
        warn "WARNING: Skipping installer command: #{command}"
        return true
      end

      success = false
      puts "Launching installer with command: #{command} #{@installer_options}"

      Dir.chdir('/') do
        success = syscall("#{command} #{@installer_options}")
      end

      success
    end

    private

    def syscall(command)
      system(command)

      # rubocop:disable SpecialGlobalVars
      $?.success?
    end

    def foreman_root
      return local_foreman if local_foreman
      '/etc/foreman-installer'
    end

    def foreman_config_root
      "#{foreman_root}/scenarios.d"
    end

    def local_katello
      File.directory?("#{@root_dir}/katello-installer") ? './katello-installer' : nil
    end

    def local_foreman
      File.directory?("#{@root_dir}/foreman-installer") ? './foreman-installer' : nil
    end

    def symlink(real, link)
      return if File.symlink?(link)
      `rm -rf #{link}` if File.exist?(link)
      File.symlink(real, link)
    end

  end
end

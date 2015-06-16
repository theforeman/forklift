require 'yaml'
require 'English'

module KatelloDeploy
  class Installer

    attr_accessor :installer_options, :skip_installer, :type, :local_path, :installers

    def initialize(args = {})
      self.installer_options = args.fetch(:installer_options, '')
      self.skip_installer = args.fetch(:skip_installer, false)
      self.type = args.fetch(:type, 'katello')
      self.local_path = args.fetch(:local_path, nil)
      self.installers = YAML.load_file('config/installers.yaml')
    end

    def install
      install_puppet
      install_packages(@installers[@type.to_s]['packages'])
      run_installer(@installers[@type.to_s]['installer'])
    end

    def install_puppet
      if system('command -v gem >/dev/null 2>&1') && system('gem list | grep puppet > /dev/null')
        # Remove puppet gem to allow installing the package
        puts 'Uninstalling puppet gem'
        system('gem uninstall puppet')
        system('yum -y remove puppet')
      end

      # ensure puppet is installed
      system('yum -y update puppet')
    end

    def install_packages(packages)
      system("yum -y install #{packages.join(' ')}")
    end

    def run_installer(command)
      if @skip_installer
        warn "WARNING: Skipping installer command: #{command}"
        return true
      end

      success = false
      command = "./bin/#{command}" if @local_path
      puts "Launching installer with command: #{command} #{@installer_options}"

      if @local_path
        Dir.chdir(@local_path) do
          success = syscall("#{command} #{@installer_options}")
        end
      else
        success = syscall("#{command} #{@installer_options}")
      end

      success
    end

    private

    def syscall(command)
      system(command)
      $CHILD_STATUS == 0
    end

  end
end

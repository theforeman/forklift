#!/usr/bin/env ruby

require 'optparse'
require './lib/kernel'
require './lib/katello_deploy'

# default options
options = {
  :metapackage => 'katello',
  :installer => 'katello-installer',
  :katello_version => 'nightly',
  :foreman_version => 'nightly',
  :install_type => 'katello',
  :skip_installer => false,
  :koji_task => [],
  :module_prs => []
}

OptionParser.new do |opts|
  opts.banner = "Usage: ./setup.rb [options]"

  opts.on("--os [OS]", "Set OS manually") do |os|
    options[:os] = os.downcase
  end

  opts.on("--install-type [INSTALL_TYPE]", [:katello, :devel, :sam, :foreman], "Installation type") do |type|
    options[:install_type] = type
  end

  opts.on("--devel-user [USERNAME]", "User to setup development environment for") do |devuser|
    options[:devel_user] = devuser
  end

  opts.on("--installer-options [OPTIONS]", "Options to pass to katello-installer") do |installer_opts|
    options[:installer_options] = installer_opts
  end

  opts.on("--skip-installer", "Skip the final installer command and print instead") do |devel|
    options[:skip_installer] = true
  end

  opts.on("--deployment-dir [DIRECTORY]", "Set a custom path for installing to (defaults to /home/USERNAME)") do |dir|
    options[:deployment_dir] = dir
  end

  opts.on("--katello-version [KATELLO_VERSION]", [:nightly, '2.1', '2.2', '2.3'], "Set the version of Katello to install nightly|2.1|2.2|2.3") do |version|
    options[:katello_version] = version
  end

  opts.on("--foreman-version [FOREMAN_VERSION]", [:nightly, '1.7', '1.8', '1.9'], "Set the version of Foreman to install nightly|1.7|1.8|1.9") do |version|
    options[:foreman_version] = version
  end

  opts.on("--koji-repos", "Use the repos on Koji instead of the release repos") do |koji|
    options[:koji_repos] = true
  end

  opts.on("--koji-task [TASK ID]", Array, "ID of a Koji build task to download RPMs from") do |task|
    task = task.is_a?(Array) ? task : [task]
    options[:koji_task] = task
  end

  opts.on("--disable-selinux", "Disable selinux prior to install") do
    options[:disable_selinux] = true
  end

  opts.on("--module-prs [MODULE/PR]", Array, "Array of module and PR combinations (e.g. qpid/12)") do |module_prs|
    check = module_prs.select { |module_pr| module_pr.split('/').length != 2 }

    if !check.empty?
      opts.abort("The following module PRs are improperly formatted: #{check}")
    end

    module_prs = [] if module_prs.nil?
    options[:module_prs] = module_prs
  end

  # Check for unsupported arguments. (parse! removes elements from ARGV.)
  opts.parse!
  opts.abort("Received unsupported arguments: #{ARGV}") if ARGV.length > 0
end

system('setenforce 0') if options[:katello_version] == "2.1" || options[:devel] || options[:disable_selinux]

operating_system = KatelloDeploy::OperatingSystem.new
options[:os] ||= operating_system.detect
operating_system.supported?(options[:os])

KatelloDeploy::Processors::KojiTaskProcessor.process(options[:koji_task])
KatelloDeploy::Processors::ModulePullRequestProcessor.process(options[:module_prs], File.expand_path(File.dirname(__FILE__)))

repositories = KatelloDeploy::Repositories.new(
  :katello_version => options[:install_type] == :katello ? options[:katello_version] : nil,
  :foreman_version => options[:install_type] == :foreman ? options[:foreman_version] : nil,
  :os_version => operating_system.version(options[:os]),
  :distro => operating_system.distro(options[:os])
)
configured = repositories.configure(options[:koji_repos])
exit(1) unless configured

installer_options = KatelloDeploy::Processors::InstallerOptionsProcessor.process(
  :installer_options => options[:installer_options],
  :devel_user => options[:devel_user],
  :deployment_dir => options[:deployment_dir]
)
installer = KatelloDeploy::Installer.new(
  :installer_options => installer_options,
  :skip_installer => options[:skip_installer],
  :type => options[:install_type],
  :local_path => (File.directory?('./katello-installer') && options[:katello_version] == 'nightly') ? './katello-installer' : nil
)
success = installer.install

KatelloDeploy::Processors::ScriptsProcessor.process

exit(1) unless success

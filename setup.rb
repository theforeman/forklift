#!/usr/bin/env ruby

require 'optparse'
require './lib/kernel'
require './lib/forklift'

# default options
options = {
  :scenario => 'katello',
  :version => 'nightly',
  :skip_installer => false,
  :koji_task => [],
  :module_prs => [],
  :process_scripts => true
}

OptionParser.new do |opts|
  opts.banner = "Usage: ./setup.rb [options]"

  opts.on("--os [OS]", "Set OS manually") do |os|
    options[:os] = os.downcase
  end

  opts.on("--scenario [INSTALL_TYPE]", ['foreman', 'katello', 'katello-devel'], "Installation type") do |type|
    options[:scenario] = type
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

  opts.on("--puppet-four", "Use puppet 4") do |devel|
    options[:puppet_four] = true
  end

  opts.on("--deployment-dir [DIRECTORY]", "Set a custom path for installing to (defaults to /home/USERNAME)") do |dir|
    options[:deployment_dir] = dir
  end

  opts.on("--version [VERSION]", ['nightly', '1.7', '1.8', '1.9', '1.10', '1.11', '1.12', '1.13'], "Set the version of Foreman to install") do |version|
    options[:version] = version
  end

  opts.on("--katello-version [KATELLO_VERSION]", ['nightly', '2.3', '2.4', '3.0', '3.1', '3.2'], "Set the version of Katello to install") do |version|
    options[:katello_version] = version
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

  opts.on("--[no-]scripts", "Run (or do not) any scripts located in the /scripts directory") do |scripts|
    options[:process_scripts] = scripts
  end

  # Check for unsupported arguments. (parse! removes elements from ARGV.)
  opts.parse!
  opts.abort("Received unsupported arguments: #{ARGV}") if ARGV.length > 0
end

system('setenforce 0') if options[:katello_version] == "2.1" || options[:devel] || options[:disable_selinux]

operating_system = Forklift::OperatingSystem.new
options[:os] ||= operating_system.detect
operating_system.supported?(options[:os])

repositories = Forklift::Repositories.new(
  :version => options[:version],
  :os_version => operating_system.version(options[:os]),
  :scenario => options[:scenario],
  :distro => operating_system.distro(options[:os]),
  :puppet_four => options[:puppet_four]
)
configured = repositories.configure(options[:koji_repos])
exit(1) unless configured

Forklift::Processors::KojiTaskProcessor.process(options[:koji_task])

installer_options = Forklift::Processors::InstallerOptionsProcessor.process(
  :installer_options => options[:installer_options],
  :devel_user => options[:devel_user],
  :deployment_dir => options[:deployment_dir]
)

installer = Forklift::Installer.new(
  :installer_options => installer_options,
  :skip_installer => options[:skip_installer],
  :scenario => options[:scenario],
  :root_dir => Dir.pwd,
  :puppet_four => options[:puppet_four]
)
success = installer.setup

Forklift::Processors::ModulePullRequestProcessor.process(options[:module_prs], File.expand_path(File.dirname(__FILE__)))

success = installer.install

Forklift::Processors::ScriptsProcessor.process if options[:process_scripts]

exit(1) unless success

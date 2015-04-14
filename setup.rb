#!/usr/bin/env ruby

require 'optparse'
require './helper'
require './lib/koji-downloader'
require './lib/repo-maker'
require './lib/module-pull-request'

# Hash of katello_version => foreman_version
foreman_version = {
  "nightly" => "nightly",
  "2.1" => "releases/1.7",
  "2.2" => "releases/1.8"
}

module Kernel
  def system_with_debug(*args)
    puts
    puts "Running shell command: #{args.join(" ")}"
    system_without_debug(*args)
  end

  # alias_method_chain :system, :debug
  alias_method :system_without_debug, :system
  alias_method :system, :system_with_debug
end

# default options
options = {
  :metapackage => 'katello',
  :installer => 'katello-installer'
}

supported_os = ['rhel6', 'centos6', 'fedora19', 'rhel7', 'centos7']

OptionParser.new do |opts|
  opts.banner = "Usage: ./setup.rb [options]"

  opts.on("--os [OS]", "Set OS manually") do |os|
    options[:os] = os.downcase
  end

  opts.on("--devel", "Setup a development environment") do |devel|
    options[:devel] = true
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

  opts.on("--version [VERSION]", [:nightly, '2.1', '2.2'], "Set the version of Katello to install nightly|2.1|2.2") do |version|
    options[:version] = version
  end

  opts.on("--koji-repos", "Use the repos on Koji instead of the release repos") do |koji|
    options[:koji_repos] = true
  end

  opts.on("--koji-task [TASK ID]", Array, "ID of a Koji build task to download RPMs from") do |task|
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

    options[:module_prs] = module_prs
  end

  opts.on("--sam", "Install SAM instead of Katello") do
    options[:metapackage] = 'katello-sam'
    options[:installer] = 'sam-installer'
  end

  # Check for unsupported arguments. (parse! removes elements from ARGV.)
  opts.parse!
  opts.abort("Received unsupported arguments: #{ARGV}") if ARGV.length > 0
end

options[:version] = 'nightly' if options[:version].nil?

# If /vagrant exists, cd to it:
if File.directory?('/vagrant/')
  Dir.chdir('/vagrant/')
end

if options[:koji_task]
  tasks = options[:koji_task].is_a?(Array) ? options[:koji_task] : [options[:koji_task]]

  tasks.each do |task|
    downloader = KojiDownloader.new(:task_id => task, :directory => './repo')
    downloader.download
  end

  repo_maker = RepoMaker.new(:name => "Koji Scratch Repo for #{tasks.join(' ')}", :directory => './repo')
  repo_maker.create
end

if options[:module_prs]
  mpr = ModulePullRequest.new

  options[:module_prs].each do |module_pr|
    mpr.setup_pull_request(module_pr.split('/')[0], module_pr.split('/')[1])
  end
end

if options[:version] == "2.1" || options[:devel] || options[:disable_selinux]
  system('setenforce 0')
end

# Make sure to clean packages metadata
system('yum clean all')

system('yum -y update nss')

options[:os] ||= detect_os

def bootstrap_epel(release)
  epel = "[bootstrap-epel]\n" \
          "name=Bootstrap EPEL\n" \
          "failovermethod=priority\n" \
          "enabled=0\n" \
          "gpgcheck=0\n" \
          "mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-#{release}&arch=$basearch"

  File.open("/etc/yum.repos.d/bootstrap-epel.repo", 'w') { |file| file.write(epel) }
  system('yum --enablerepo=bootstrap-epel -y install epel-release')
  system('rm -f /etc/yum.repos.d/bootstrap-epel.repo')
end

def bootstrap_scl
  system('yum -y install foreman-release-scl')
end

def setup_koji_repos(os, version='nightly', foreman_version='nightly')
  foreman_version = foreman_version.gsub('releases/', '')

  katello = "[katello-koji]\n" \
             "name=katello-koji\n" \
             "enabled=1\n" \
             "gpgcheck=0\n" \
             "baseurl=http://koji.katello.org/releases/yum/katello-#{version}/katello/RHEL/#{os}/x86_64/"

  pulp = "[pulp-koji]\n" \
         "name=pulp-koji\n" \
         "enabled=1\n" \
         "gpgcheck=0\n" \
         "baseurl=http://koji.katello.org/releases/yum/katello-#{version}/pulp/RHEL/#{os}/x86_64/"

  candlepin = "[candlepin-koji]\n" \
              "name=candlepin-koji\n" \
              "enabled=1\n" \
              "gpgcheck=0\n" \
              "baseurl=http://koji.katello.org/releases/yum/katello-#{version}/candlepin/RHEL/#{os}/x86_64/"

  foreman = "[foreman-koji]\n" \
              "name=foreman-koji\n" \
              "enabled=1\n" \
              "gpgcheck=0\n" \
              "baseurl=http://koji.katello.org/releases/yum/foreman-#{foreman_version}/RHEL/#{os}/x86_64/"

  plugins = "[foreman-plugins]\n" \
              "name=foreman-plugins\n" \
              "enabled=1\n" \
              "gpgcheck=0\n" \
              "baseurl=http://yum.theforeman.org/plugins/#{foreman_version}/#{os}/x86_64/"


  File.open("/etc/yum.repos.d/katello-koji.repo", 'w') { |file| file.write(katello) }
  File.open("/etc/yum.repos.d/pulp-koji.repo", 'w') { |file| file.write(pulp) }
  File.open("/etc/yum.repos.d/candlepin-koji.repo", 'w') { |file| file.write(candlepin) }
  File.open("/etc/yum.repos.d/foreman-koji.repo", 'w') { |file| file.write(foreman) }
  File.open("/etc/yum.repos.d/foreman-plugins.repo", 'w') { |file| file.write(plugins) }
end

if options[:os] == 'fedora19'

  system('yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/Fedora/19/x86_64/katello-repos-latest.rpm')
  system('yum -y localinstall http://yum.theforeman.org/nightly/f19/x86_64/foreman-release.rpm')

  # Facter parses the F19 fedora-release improperly due to the umlaut and apstrophe in the code name
  system('cp ./fedora-release /etc')

elsif ['centos6', 'rhel6'].include? options[:os]

  # Clean out past runs if necessary:
  system('rpm -e epel-release')
  system('rpm -e foreman-release')
  system('rpm -e katello-repos')
  system('rpm -e puppetlabs-release')
  system('rm -f /etc/yum.repos.d/scl.repo')

  if options[:os] == 'rhel6'
    # Setup RHEL specific repos
    system('yum -y  --disablerepo="*" --enablerepo=rhel-6-server-rpms install yum-utils wget')
    system('yum repolist') # TODO: necessary?
    system('yum-config-manager --disable "*"')
    system('yum-config-manager --enable epel')
    system('subscription-manager repos --enable rhel-6-server-rpms --enable rhel-6-server-optional-rpms')
    # As epel repo uses mirrorlist.
    system('yum -y install yum-plugin-fastestmirror')
  end

  bootstrap_epel(6)
  system('yum -y localinstall http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm')

  if options[:koji_repos]
    setup_koji_repos(6, options[:version], foreman_version[options[:version]])
  else
    system("yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/#{options[:version]}/katello/RHEL/6Server/x86_64/katello-repos-latest.rpm")
    system("yum -y localinstall http://yum.theforeman.org/#{foreman_version[options[:version]]}/el6/x86_64/foreman-release.rpm")
  end
  bootstrap_scl
elsif ['rhel7', 'centos7'].include? options[:os]

  # Clean out past runs if necessary:
  system('rpm -e epel-release')
  system('rpm -e foreman-release')
  system('rpm -e katello-repos')
  system('rpm -e puppetlabs-release')

  if options[:os] == 'rhel7'
    # Setup RHEL specific repos
    system('yum -y  --disablerepo="*" --enablerepo=rhel-7-server-rpms install yum-utils wget')
    system('yum repolist') # TODO: necessary?
    system('yum-config-manager --disable "*"')
    system('yum-config-manager --enable epel')
    system('subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-extras-rpms --enable rhel-7-server-optional-rpms')
    # As epel repo uses mirrorlist and yum vars.
    system('yum -y install yum-plugin-fastestmirror')
  end

  bootstrap_epel(7)
  system('yum -y localinstall http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm')

  if options[:koji_repos]
    setup_koji_repos(7, options[:version], foreman_version[options[:version]])
  else
    system("yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/#{options[:version]}/katello/RHEL/7/x86_64/katello-repos-latest.rpm")
    system("yum -y localinstall http://yum.theforeman.org/#{foreman_version[options[:version]]}/el7/x86_64/foreman-release.rpm")
  end
  bootstrap_scl
else
  $stderr.puts "OS #{options[:os]} is not supported. Must be one of #{supported_os.join(", ")}."
  exit(1)
end

if system('gem list | grep puppet > /dev/null')
  # Remove puppet gem to allow installing the package
  puts 'Uninstalling puppet gem'
  system('gem uninstall puppet')
  system('yum -y remove puppet')
end

# ensure puppet is installed
system('yum -y update puppet')

if options.has_key?(:devel)
  system('yum -y install rubygems')
  system('yum -y install rubygem-kafo')
  system('yum -y install katello-devel-installer')
else
  system("yum -y install #{options[:metapackage]}") # "katello" or "katello-sam"
end

installer_options = options[:installer_options] || ""
install_command = "#{options[:installer]} #{installer_options}" # "katello-installer" or "sam-installer"

if options.has_key?(:devel)

  # Plain devel install, really only useful for the default vagrant setup:
  install_command = "katello-devel-installer #{installer_options}"

  # If a devel user was specified we assume a logical setup where the group and home dir are known:
  if options.has_key?(:devel_user)
    directory =  options[:deployment_dir] || "/home/#{options[:devel_user]}"
    install_command = "#{install_command} --user=#{options[:devel_user]} --group=#{options[:devel_user]} --deployment-dir=#{directory} #{installer_options}"
  end
end

if options.has_key?(:skip_installer)
  puts "WARNING: Skipping installer command: #{install_command}"
  exit 0
end

exit_code = 0
puts "Launching installer with command: #{install_command}"
if File.directory?('./katello-installer') && options[:version] == 'nightly'
  Dir.chdir('./katello-installer') do
    system("./bin/#{install_command}")
    exit_code = $?.exitstatus
  end
else

  # Prevent a git clone failure when the devel user cannot chdir back to the
  # starting directory. (/root often)
  if options.has_key?(:devel_user)
    Dir.chdir("/home/#{options[:devel_user]}")
  end

  system("#{install_command}")
  exit_code = $?.exitstatus
end

if exit_code == 0 && File.directory?('scripts')
  Dir.chdir('scripts')
  scripts = Dir.glob('*').select{ |e| File.file? e }

  scripts.each do |script|
    system("./#{script}")
  end
end

exit(exit_code)

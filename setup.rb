#!/usr/bin/env ruby

# TODO: automatically figure out the OS

require 'optparse'

# Hash of katello_version => foreman_version
foreman_version = {
  "nightly" => "nightly",
  "2.0" => "releases/1.6"
}

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ./setup.rb [options] rhel6|centos6|fedora19|rhel7|centos7"

  opts.on("--devel", "Setup a development environment") do |devel|
    options[:devel] = true
  end

  opts.on("--capsule", "Deploy a capsule") do |capsule|
    options[:capsule] = true
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

  opts.on("--version [VERSION]", [:nightly, '2.0'], "Set the version of Katello to install nightly|2.0") do |version|
    options[:version] = version
  end

end.parse!

options[:version] = 'nightly' if options[:version].nil?

# If /vagrant exists, cd to it:
if File.directory?('/vagrant/')
  Dir.chdir('/vagrant/')
end

# TODO: Would be nice to not require this:
system('setenforce 0')

# Make sure to clean packages metadata
system('yum clean all')

system('yum -y update nss')

if ARGV.include?('fedora19')

  system('yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/Fedora/19/x86_64/katello-repos-latest.rpm')
  system('yum -y localinstall http://yum.theforeman.org/nightly/f19/x86_64/foreman-release.rpm')

  # Facter parses the F19 fedora-release improperly due to the umlaut and apstrophe in the code name
  system('cp ./fedora-release /etc')

elsif ARGV.include?('centos6') || ARGV.include?('rhel6')

  # Clean out past runs if necessary:
  system('rpm -e epel-release')
  system('rpm -e foreman-release')
  system('rpm -e katello-repos')
  system('rpm -e puppetlabs-release')
  system('rm -f /etc/yum.repos.d/scl.repo')

  if ARGV.include?('rhel6')
    # Setup RHEL specific repos
    system('yum -y  --disablerepo="*" --enablerepo=rhel-6-server-rpms install yum-utils wget')
    system('yum repolist') # TODO: necessary?
    system('yum-config-manager --disable "*"')
    system('yum-config-manager --enable rhel-6-server-rpms epel')
    system('yum-config-manager --enable rhel-6-server-optional-rpms')
    system('yum-config-manager --enable rhel-server-rhscl-6-rpms')
  end

  # NOTE: Using CentOS SCL even on RHEL to simplify subscription usage.
  if !File.directory?('/etc/yum.repos.d/scl.repo')
    system('cp ./scl.repo /etc/yum.repos.d/')
  end

  system('yum -y localinstall http://mirror.pnl.gov/epel/6/x86_64/epel-release-6-8.noarch.rpm')
  system('yum -y localinstall http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm')
  system("yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/#{options[:version]}/katello/RHEL/6Server/x86_64/katello-repos-latest.rpm")
  system("yum -y localinstall http://yum.theforeman.org/#{foreman_version[options[:version]]}/el6/x86_64/foreman-release.rpm")

elsif ARGV.include?('centos7') || ARGV.include?('rhel7')

  # Clean out past runs if necessary:
  system('rpm -e epel-release')
  system('rpm -e foreman-release')
  system('rpm -e katello-repos')
  system('rpm -e puppetlabs-release')

  if ARGV.include?('rhel7')
    # Setup RHEL specific repos
    system('yum -y  --disablerepo="*" --enablerepo=rhel-7-server-rpms install yum-utils wget')
    system('yum repolist') # TODO: necessary?
    system('yum-config-manager --disable "*"')
    system('yum-config-manager --enable rhel-7-server-rpms epel')
    system('yum-config-manager --enable rhel-7-server-extras-rpms')
    system('yum-config-manager --enable rhel-7-server-optional-rpms')
    system('yum-config-manager --enable rhel-server-rhscl-7-rpms')
  end

  system('yum -y localinstall https://www.softwarecollections.org/en/scls/rhscl/v8314/epel-7-x86_64/download/rhscl-v8314-epel-7-x86_64.noarch.rpm')
  system('yum -y localinstall https://www.softwarecollections.org/en/scls/rhscl/ruby193/epel-7-x86_64/download/rhscl-ruby193-epel-7-x86_64.noarch.rpm')
  system('yum -y localinstall http://download-i2.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-2.noarch.rpm')
  system('yum -y localinstall http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm')
  system("yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/#{options[:version]}/katello/RHEL/7/x86_64/katello-repos-latest.rpm")
  system("yum -y localinstall http://yum.theforeman.org/#{foreman_version[options[:version]]}/el7/x86_64/foreman-release.rpm")

end

if system('gem list | grep puppet > /dev/null')
  # Remove puppet gem to allow installing the package
  puts 'Uninstalling puppet gem'
  system('gem uninstall puppet')
  system('yum -y remove puppet')
end

#ensure puppet is installed
system('yum -y update puppet')

if options.has_key?(:devel)
  system('yum -y install rubygems')
  system('yum -y install rubygem-kafo')
  system('yum -y install katello-installer')
elsif options.has_key?(:capsule)
  system('yum -y install katello-installer')
else
  system('yum -y install katello')
end

installer_options = options[:installer_options] || ""

if options.has_key?(:capsule)
  install_command = "capsule-installer #{installer_options}"
else
  install_command = "katello-installer #{installer_options}"
end

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

exit(exit_code)

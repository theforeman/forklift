#!/usr/bin/env ruby

# TODO: automatically figure out the OS

require 'optparse'

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ./setup.rb [options] rhel6|centos6|fedora19"

  opts.on("--force", "Do not exit on error") do |devel|
    $options[:force] = true
  end

  opts.on("--devel", "Setup a development environment") do |devel|
    $options[:devel] = true
  end

  opts.on("--devel-user [USERNAME]", "User to setup development environment for") do |devuser|
    $options[:devel_user] = devuser
  end

  opts.on("--skip-installer", "Skip the final installer command and print instead") do |devel|
    $options[:skip_installer] = true
  end

  opts.on("--deployment-dir [DIRECTORY]", "Set a custom path for installing to (defaults to /home/USERNAME)") do |dir|
    $options[:deployment_dir] = dir
  end

end.parse!

def system_or_die(command)
  $options[:force] && return
  system(command) || exit(1)
end

# If /vagrant exists, cd to it:
if File.directory?('/vagrant/')
  Dir.chdir('/vagrant/')
end

# TODO: Would be nice to not require this:
system_or_die('setenforce 0')

if ARGV.include?('fedora19')

  system_or_die('yum -y localinstall http://fedorapeople.org/groups/katello/releases/yum/nightly/Fedora/19/x86_64/katello-repos-latest.rpm')
  system_or_die('yum -y localinstall http://yum.theforeman.org/nightly/f19/x86_64/foreman-release.rpm')

  # Facter parses the F19 fedora-release improperly due to the umlaut and apstrophe in the code name
  system_or_die('cp ./fedora-release /etc')

elsif ARGV.include?('centos6') || ARGV.include?('rhel6')

  # Clean out past runs if necessary:
  system_or_die('rpm -e epel-release')
  system_or_die('rpm -e foreman-release')
  system_or_die('rpm -e katello-repos')
  system_or_die('rpm -e puppetlabs-release')
  system_or_die('rm -f /etc/yum.repos.d/scl.repo')

  if ARGV.include?('rhel6')
    # Setup RHEL specific repos
    system_or_die('yum -y  --disablerepo="*" --enablerepo=rhel-6-server-rpms install yum-utils wget')
    system_or_die('yum repolist') # TODO: necessary?
    system_or_die('yum-config-manager --disable "*"')
    system_or_die('yum-config-manager --enable rhel-6-server-rpms epel')
    system_or_die('yum-config-manager --enable rhel-6-server-optional-rpms')
    system_or_die('yum-config-manager --enable rhel-server-rhscl-6-rpms')
  end

  # NOTE: Using CentOS SCL even on RHEL to simplify subscription usage.
  if !File.directory?('/etc/yum.repos.d/scl.repo')
    system_or_die('cp ./scl.repo /etc/yum.repos.d/')
  end

  system_or_die('yum -y localinstall http://fedorapeople.org/groups/katello/releases/yum/nightly/RHEL/6Server/x86_64/katello-repos-latest.rpm')
  system_or_die('yum -y localinstall http://yum.theforeman.org/nightly/el6/x86_64/foreman-release.rpm')
  system_or_die('yum -y localinstall http://mirror.pnl.gov/epel/6/x86_64/epel-release-6-8.noarch.rpm')
  system_or_die('yum -y localinstall http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm')
end

if $options.has_key?(:devel)
  system_or_die('yum -y install rubygems')
  system_or_die('yum -y install rubygem-kafo')
  system_or_die('yum -y install katello-installer')
else
  system_or_die('yum -y install katello')
end

if system('gem list | grep puppet > /dev/null')
  # Remove puppet gem to allow installing the package
  puts 'Uninstalling puppet gem'
  system('gem uninstall puppet')
else
  # Will update puppet package if it is already installed
  puts 'Updating puppet package'
  system('yum -y update puppet')
end

install_command = 'katello-installer -v -d'
if $options.has_key?(:devel)

  # Plain devel install, really only useful for the default vagrant setup:
  install_command = "katello-devel-installer -v -d"

  # If a devel user was specified we assume a logical setup where the group and home dir are known:
  if $options.has_key?(:devel_user)
    directory =  $options[:deployment_dir] || "/home/#{$options[:devel_user]}"
    install_command = "#{install_command} --user=#{$options[:devel_user]} --group=#{$options[:devel_user]} --deployment-dir=#{directory}"
  end
end

if $options.has_key?(:skip_installer)
  puts "WARNING: Skipping installer command: #{install_command}"
  exit 0
end

puts "Launching installer with command: #{install_command}"
if File.directory?('./katello-installer')
  Dir.chdir('./katello-installer') do
    system_or_die("./bin/#{install_command}")
  end
else

  # Prevent a git clone failure when the devel user cannot chdir back to the
  # starting directory. (/root often)
  if $options.has_key?(:devel_user)
    Dir.chdir("/home/#{$options[:devel_user]}")
  end

  system_or_die("#{install_command}")
end

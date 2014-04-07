#!/usr/bin/env ruby

# TODO: automatically figure out the OS

# TODO: devel user, sudo setup?
# TODO: if run for devel user, make sure we run from correct directory

# TODO: Would be nice to not require this:
system('setenforce 0')

if ARGV.include?('fedora19')

  system('yum -y localinstall http://fedorapeople.org/groups/katello/releases/yum/nightly/Fedora/19/x86_64/katello-repos-latest.rpm')
  system('yum -y localinstall http://yum.theforeman.org/nightly/f19/x86_64/foreman-release.rpm')

  # Facter parses the F19 fedora-release improperly due to the umlaut and apstrophe in the code name
  system('cp ./fedora-release /etc')

elsif ARGV.include?('centos') || ARGV.include?('rhel')

  # Clean out past runs if necessary:
  system('rpm -e epel-release')
  system('rpm -e foreman-release')
  system('rpm -e katello-repos')
  system('rm -f /etc/yum.repos.d/scl.repo')

  if ARGV.include?('rhel')
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

  system('yum -y localinstall http://fedorapeople.org/groups/katello/releases/yum/nightly/RHEL/6Server/x86_64/katello-repos-latest.rpm')
  system('yum -y localinstall http://yum.theforeman.org/nightly/el6/x86_64/foreman-release.rpm')
  system('yum -y localinstall http://mirror.pnl.gov/epel/6/x86_64/epel-release-6-8.noarch.rpm')
  system('yum -y localinstall http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm')
end

if ARGV.include?('--devel')
  system('yum -y install rubygems')
  system('yum -y install rubygem-kafo')
  system('yum -y install katello-installer')
else
  system('yum -y install katello')
end

install_command = ARGV.include?('--devel') ? 'katello-devel-installer' : 'katello-installer'

if File.directory?('/vagrant/katello-installer')
  Dir.chdir('/vagrant/katello-installer') do
    system("./bin/#{install_command} -v -d")
  end
else
  # TODO: get devel user options in here somehow:
  system("#{install_command} -v -d")
end

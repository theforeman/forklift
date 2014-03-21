#!/usr/bin/env ruby

if ARGV.include?('fedora19')
  system('yum -y localinstall http://fedorapeople.org/groups/katello/releases/yum/nightly/Fedora/19/x86_64/katello-repos-latest.rpm')
  system('yum -y localinstall http://yum.theforeman.org/nightly/f19/x86_64/foreman-release.rpm')

  # Facter parses the F19 fedora-release improperly due to the umlaut and apstrophe in the code name
  system('cp ./fedora-release /etc')
elsif ARGV.include?('centos') || ARGV.include?('rhel')

  if !File.directory?('/etc/rum.repos.d/scl.repo')
    system('cp ./scl.repo /etc/yum.repos.d/')
  end

  system('yum -y localinstall http://fedorapeople.org/groups/katello/releases/yum/nightly/RHEL/6Server/x86_64/katello-repos-latest.rpm')
  system('yum -y localinstall http://mirror.pnl.gov/epel/6/x86_64/epel-release-6-8.noarch.rpm')
  system('yum -y localinstall http://yum.theforeman.org/nightly/el6/x86_64/foreman-release.rpm')
end

if ARGV.include?('--devel')
  system('yum -y install rubygems')
  system('yum -y install rubygem-kafo')
else
  system('yum -y install katello')
end

install_command = ARGV.include?('--devel') ? 'katello-devel-installer' : 'katello-installer'

if File.directory?('/vagrant/katello-installer')
  Dir.chdir('/vagrant/katello-installer') do
    system("./bin/#{install_command} -v -d")
  end
else
  system("#{install_command} -v -d")
end

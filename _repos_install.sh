setenforce 0

if [ ! -e "/etc/yum.repos.d/scl.repo" ]
then
  cp ./scl.repo /etc/yum.repos.d/
fi

yum -y localinstall http://fedorapeople.org/groups/katello/releases/yum/nightly/RHEL/6Server/x86_64/katello-repos-latest.rpm 2> /dev/null
yum -y localinstall http://mirror.pnl.gov/epel/6/x86_64/epel-release-6-8.noarch.rpm 2> /dev/null
yum -y localinstall http://yum.theforeman.org/nightly/el6/x86_64/foreman-release.rpm 2> /dev/null
yum -y localinstall http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm 2> /dev/null
yum -y install katello

if [ -d /vagrant/katello-installer ]
then
  cd /vagrant/katello-installer
  ./bin/katello-installer -v -d
else
  katello-installer -v -d
fi


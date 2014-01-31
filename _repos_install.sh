setenforce 0

pushd /etc/yum.repos.d/
if [ ! -e "scl.repo" ]
then
  yum -y install wget
  wget http://dev.centos.org/centos/6/SCL/scl.repo
fi
popd

yum -y localinstall http://fedorapeople.org/groups/katello/releases/yum/nightly/RHEL/6Server/x86_64/katello-repos-latest.rpm 2> /dev/null
yum -y localinstall http://mirror.pnl.gov/epel/6/x86_64/epel-release-6-8.noarch.rpm > /dev/null
yum -y localinstall http://yum.theforeman.org/nightly/el6/x86_64/foreman-release.rpm 2> /dev/null
yum -y install katello

if [ -d /vagrant/katello-installer ]
then
  cd /vagrant
  ./bin/katello-installer -v -d
else
  katello-installer -v -d
fi


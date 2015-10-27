cd ..
./setup.rb --install-type=foreman --skip-installer
mkdir tmp
pushd tmp
git clone https://github.com/mbacovsky/kafo.git
pushd kafo
git checkout 10162_scenarios
rm -rf /usr/share/gems/gems/kafo-*/*
cp -rf * /usr/share/gems/gems/kafo-*/
popd
popd

gem install kafo_wizards

mkdir /etc/foreman/installer-scenarios.d
cp /etc/foreman/*installer* /etc/foreman/installer-scenarios.d/

cp /vagrant/shells/foreman-installer.rb /usr/sbin/foreman-installer

foreman-installer --list-scenarios

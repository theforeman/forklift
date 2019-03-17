#!/bin/sh

# Store build time
date > /etc/vagrant_box_build_time

# Install vagrant key
mkdir -pm 700 /home/vagrant/.ssh
curl -L https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

sed -i 's/^hosts:.*files dns/hosts:      files dns myhostname/' /etc/nsswitch.conf

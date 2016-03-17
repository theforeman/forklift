#!/bin/bash -x

echo "$FOREMAN_SERVER_IP $FOREMAN_SERVER_HOSTNAME" >> /etc/hosts
yum -y localinstall https://fedorapeople.org/groups/katello/releases/yum/$KATELLO_VERSION/client/el6/x86_64/katello-client-repos-latest.rpm
yum -y install katello-agent http://$FOREMAN_SERVER_HOSTNAME/pub/katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org $FOREMAN_ORGANIZATION --activationkey="$FOREMAN_ACTIVATION_KEY"
service goferd stop
exec goferd --foreground

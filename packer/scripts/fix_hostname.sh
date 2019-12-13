#!/bin/bash

echo "Configuring HOSTNAME: $PACKER_HOSTNAME"
hostnamectl set-hostname $PACKER_HOSTNAME
SHORT_HOSTNAME=$(hostname -s)
sed -i "1i127.0.0.1 $PACKER_HOSTNAME $SHORT_HOSTNAME" /etc/hosts
echo "HOSTNAME $PACKER_HOSTNAME configured"

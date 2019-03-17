#!/bin/bash

echo "Configuring HOSTNAME: $HOSTNAME"
hostnamectl set-hostname $HOSTNAME
SHORT_HOSTNAME=$(hostname -s)
sed -i "1i127.0.0.1 $HOSTNAME $SHORT_HOSTNAME" /etc/hosts
echo "HOSTNAME $HOSTNAME configured"

#!/bin/bash

DEBIAN_FRONTEND=noninteractive

if [ "$EUID" -ne 0 ]
  then echo "Please run this script as the root user or with sudo"
  exit
fi

apt-get update
apt-get -y dist-upgrade
apt-get -y install qemu-kvm qemu-utils genisoimage
mkdir -p /kvm/images
mkdir -p /kvm/vms/salt
mkdir /kvm/vms/dnsmasq

wget https://cdimage.debian.org/cdimage/openstack/current-9/debian-9-openstack-amd64.raw -O /kvm/images/debian9.raw
curl https://raw.githubusercontent.com/GeorgiaCyber/kinetic/master/bootstrap/resources/common.xml | sed 's/{{ name }}/salt/g' > /kvm/vms/salt/config.xml
curl https://raw.githubusercontent.com/GeorgiaCyber/kinetic/master/bootstrap/resources/common.xml | sed 's/{{ name }}/dnsmasq/g' > /kvm/vms/dnsmasq/config.xml

#!/bin/bash
set -exo pipefail

sudo dnf install -y virt-manager
sudo dnf install -y vagrant
sudo dnf install -y gcc libvirt libvirt-devel libxml2-devel make ruby-devel libguestfs-tools
sudo dnf install -y qemu qemu-kvm bridge-utils
sudo yum install -y libvirt-client

#sudo systemctl enable libvirtd
#sudo systemctl start libvirtd

vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-sshfs
sudo modprobe -r kvm_intel
sudo modprobe kvm_intel nested=1
sudo usermod -a -G libvirt tester

sudo systemctl enable virtlogd.socket
sudo systemctl restart virtlogd.socket

#sudo virsh net-autostart vagrant-libvirt-new
#sudo virsh net-autostart vagrant-private-dhcp


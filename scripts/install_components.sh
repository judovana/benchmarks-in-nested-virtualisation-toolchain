#!/bin/bash

## resolve folder of this script, following all symlinks,
## http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SCRIPT_SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  SCRIPT_DIR="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
readonly SCRIPT_ORIGIN="$( cd -P "$( dirname "$SCRIPT_SOURCE" )" && pwd )"

RUN_TYPE=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep ^RUN_TYPE= | sed "s/.*=//")

set -exo pipefail

sudo dnf install -y --disablerepo fedora-modular virt-manager
sudo dnf install -y --disablerepo fedora-modular rubygem-rexml
sudo dnf install -y --disablerepo fedora-modular vagrant
sudo dnf install -y --disablerepo fedora-modular gcc libvirt libvirt-devel libxml2-devel make ruby-devel libguestfs-tools
sudo dnf install -y --disablerepo fedora-modular qemu qemu-kvm bridge-utils
sudo yum install -y --disablerepo fedora-modular libvirt-client

#sudo systemctl enable libvirtd
#sudo systemctl start libvirtd

vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-sshfs
if [ "x$RUN_TYPE" != "xVM_in_cont" ]; then
  sudo modprobe -r kvm_intel
  sudo modprobe kvm_intel nested=1
  sudo usermod -a -G libvirt tester
  sudo systemctl enable virtlogd.socket
  sudo systemctl restart virtlogd.socket
fi
#sudo virsh net-autostart vagrant-libvirt-new
#sudo virsh net-autostart vagrant-private-dhcp


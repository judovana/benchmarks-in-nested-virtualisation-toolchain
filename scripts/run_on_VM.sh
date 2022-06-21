#!/bin/bash
set -exo pipefail

export WORKSPACE=`mktemp -d`
mkdir  $WORKSPACE/in
mkdir  $WORKSPACE/out

SCRIPT_ORIGIN=/home/tester/diplomka/benchmarks-in-nested-virtualisation-toolchain/scripts
VIRTUAL_WORKSPACE=/mnt/workspace
cp $SCRIPT_ORIGIN/script.sh  $WORKSPACE/in
pushd /home/tester/diplomka/nested/f34-x64
  vagrant destroy -f
  vagrant up
  vagrant ssh -c "bash $VIRTUAL_WORKSPACE/in/script.sh"
popd

find $WORKSPACE
cp -r $WORKSPACE/out  $VIRTUAL_WORKSPACE



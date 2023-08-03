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
	readonly REPO_DIR=`dirname $SCRIPT_ORIGIN`
readonly REPO_NAME=`basename $REPO_DIR`

set -exo pipefail

JDK=$2
JDK_NAME=`basename ${JDK}`
COUNTER=$1
IS_CONTAINER=$3

export WORKSPACE=`mktemp -d`
mkdir  $WORKSPACE/in
mkdir  $WORKSPACE/out

VAGRANTFILES_ORIGIN=$SCRIPT_ORIGIN/../vagrantfiles
VIRTUAL_WORKSPACE=/mnt/workspace
cp  ~/.ssh/tester_rsa  $WORKSPACE/in
cp -r $REPO_DIR  $WORKSPACE/in
cp $JDK $WORKSPACE/in

mkdir $SCRIPT_ORIGIN/../results || true
mkdir $SCRIPT_ORIGIN/../results/${JDK_NAME} || true
mkdir $SCRIPT_ORIGIN/../results/${JDK_NAME}/${COUNTER}

pushd $SCRIPT_ORIGIN/../vagrantfiles/normal/$(cat $SCRIPT_ORIGIN/../config | grep ^MAINVM= | sed "s/.*=//")
  if [ ! "x$DEV" = "x" ] ; then
    other_params="VM_CPUS=2 VM_MEMORY=2048"
    export VM_CPUS=3
    export VM_MEMORY=4096
    if [ "x$DEV" = "xhalt" ] ; then
      vagrant halt
    else
      vagrant up
      vagrant destroy -f
    fi
  else
    vagrant up
    vagrant destroy -f
  fi
  vagrant up
  #Using rsync because permission issues with cp
  #vagrant ssh -c "rsync -av --progress $VIRTUAL_WORKSPACE/in/nested /home/tester/diplomka --exclude .git"
  vagrant ssh -c "bash $VIRTUAL_WORKSPACE/in/$REPO_NAME/scripts/create_private_key_symlink.sh"
  if [ $IS_CONTAINER = False ] ; then 
    vagrant ssh -c "bash $VIRTUAL_WORKSPACE/in/$REPO_NAME/scripts/install_components.sh"
  fi
  vagrant halt
  vagrant up
  if [ $IS_CONTAINER = True ] ; then 
    vagrant ssh -c "WORKSPACE=$VIRTUAL_WORKSPACE $other_params bash $VIRTUAL_WORKSPACE/in/$REPO_NAME/scripts/run_container_on_VM.sh $COUNTER $JDK"
  else
    vagrant ssh -c "WORKSPACE=$VIRTUAL_WORKSPACE $other_params bash $VIRTUAL_WORKSPACE/in/$REPO_NAME/scripts/run_on_VM.sh $COUNTER $JDK"
  fi
  find $WORKSPACE
popd

rm -rfv $WORKSPACE	



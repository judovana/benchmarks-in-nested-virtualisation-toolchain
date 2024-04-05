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

#DEV mode for dev machine with low HW specs
if [ ! "x$DEV" = "x" ] ; then
  export VM_CPUS=2
  export VM_MEMORY=2048
fi

#create temporary workspace if necessary
if [ "x$WORKSPACE" = "x" ] ; then 
  isTmpWs="true"
  export WORKSPACE=`mktemp -d`
  mkdir  $WORKSPACE/in
  mkdir  $WORKSPACE/out
  cp -r $REPO_DIR $WORKSPACE/in
  cp $JDK $WORKSPACE/in
fi

#create result folder structure
mkdir $SCRIPT_ORIGIN/../results || true
mkdir $SCRIPT_ORIGIN/../results/${JDK_NAME} || true
mkdir $SCRIPT_ORIGIN/../results/${JDK_NAME}/${COUNTER}

#check if the VM is supposed to run on real hardware host, or if the VM will be nested
RUN_TYPE=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep RUN_TYPE | sed "s/.*=//")
if [ "x$RUN_TYPE" = "xVM" ] ; then 
  LAYER=MAINVM
  VAGRANTFILES_FOLDER=normal
else
  LAYER=NESTED
  VAGRANTFILES_FOLDER=nested
fi

TOP_LEVEL_HOST=$(cat $SCRIPT_ORIGIN/../config | grep ^TOP_LEVEL_HOST= | sed "s/.*=//")

#start VM and run the selected benchmark
VIRTUAL_WORKSPACE=/mnt/workspace
pushd $SCRIPT_ORIGIN/../vagrantfiles/$VAGRANTFILES_FOLDER/$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep ^$LAYER= | sed "s/.*=//")
  vagrant destroy -f
  vagrant up
  if [ "x$isTmpWs" = "xtrue" ] || [ "x$RUN_TYPE" = "xnested_VM" ] ; then
    sudo dnf -y install /usr/bin/ssh rsync
    vagrant ssh -c "sudo dnf -y install /usr/bin/ssh rsync"
    vagrant ssh -c "rsync -av -e \"ssh -o StrictHostKeyChecking=no\"  --progress --exclude .git  tester@$TOP_LEVEL_HOST:/mnt/shared/ /mnt/shared" || echo "rsync did its best. Lets try to trust it"
  fi
  vagrant ssh -c "echo '127.0.0.1   localhost results' | sudo tee -a /etc/hosts "
  vagrant ssh -c "echo '::1         localhost results' | sudo tee -a /etc/hosts "
  vagrant ssh -c "bash $VIRTUAL_WORKSPACE/in/$REPO_NAME/scripts/script.sh $JDK"
  echo "-------------------------------------------------------------------------------------------------------------------------FINISHED SCRIPT.sh---------------------------------------------------------------"
popd

find $WORKSPACE
#find $VIRTUAL_WORKSPACE

#copy results from VM or nested VM to base host.
if [ "x$isTmpWs" = "xtrue" ] || [ "x$RUN_TYPE" = "xnested_VM" ] ; then 
  MIDDLE_POINT=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep MIDDLE_POINT | sed "s/.*=//")
  find $WORKSPACE/results/
  #mkdir -p home/tester/test/results/java-1.8.0-openjdk-jdk8u122.b01-0.ojdk8~u~upstream.hotspot.release.sdk.el7.x86_64.tarxz/1
  #rsync -av -e "ssh -o StrictHostKeyChecking=no" --relative --progress --exclude .git $WORKSPACE/results/ home/tester/test/results/${JDK_NAME}/${COUNTER}
  sudo dnf -y install /usr/bin/ssh
  if [ "x$RUN_TYPE" = "xVM" ] ; then 
    rsync -av -e "ssh -o StrictHostKeyChecking=no"  --progress --exclude .git  $WORKSPACE/out  $WORKSPACE/results tester@$TOP_LEVEL_HOST:$SCRIPT_ORIGIN/../results/${JDK_NAME}/${COUNTER}
  else
    ssh tester@$TOP_LEVEL_HOST "mkdir -p $WORKSPACE/results/${JDK_NAME}/${COUNTER}"
    rsync -av -e "ssh -o StrictHostKeyChecking=no"  --progress --exclude .git  $WORKSPACE/out  $WORKSPACE/results tester@$TOP_LEVEL_HOST:$WORKSPACE/results/${JDK_NAME}/${COUNTER}
  fi
  rm -rfv $WORKSPACE
fi



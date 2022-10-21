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
COUNTER=$1
if [ ! "x$DEV" = "x" ] ; then
  export VM_CPUS=2
  export VM_MEMORY=2048
fi

if [ "x$WORKSPACE" = "x" ] ; then 
  isTmpWs="true"
  export WORKSPACE=`mktemp -d`
  mkdir  $WORKSPACE/in
  mkdir  $WORKSPACE/out
  cp -r $REPO_DIR $WORKSPACE/in
  cp $JDK $WORKSPACE/in
fi

VIRTUAL_WORKSPACE=/mnt/workspace
pushd $SCRIPT_ORIGIN/../vagrantfiles/nested/$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep ^NESTED= | sed "s/.*=//")
  vagrant destroy -f
  vagrant up
  vagrant ssh -c "bash $VIRTUAL_WORKSPACE/in/$REPO_NAME/scripts/script.sh $JDK"
popd

find $WORKSPACE
if [ "x$isTmpWs" = "xtrue" ] ; then 
  cp -r $WORKSPACE/out  $SCRIPT_ORIGIN/../results
  rm -rfv $WORKSPACE
fi



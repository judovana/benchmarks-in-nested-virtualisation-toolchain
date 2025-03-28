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

COUNTER=$1
JDK=$2
SCRIPT_RUN_FROM_VM=$3

#get path of folder containing JDKs from config
JDK_DIR=$(cat $SCRIPT_ORIGIN/../config | grep ^JDK_DIR= | sed "s/.*=//")

if [ "x$SCRIPT_RUN_FROM_VM" == "xTrue" ] ; then
  echo pwd
  ls -l /mnt/shared/testsuites
fi

ls -l
sh $SCRIPT_ORIGIN/prepare_container.sh True
sh $SCRIPT_ORIGIN/add_jdk_to_prepared_container.sh $JDK False $JDK_DIR $SCRIPT_RUN_FROM_VM
if [ "x$SCRIPT_RUN_FROM_VM" == "xTrue" ] ; then
  sh $SCRIPT_ORIGIN/run_from_prepared_container.sh $COUNTER $JDK False
else
  sh $SCRIPT_ORIGIN/run_from_prepared_container.sh $COUNTER $JDK True
fi


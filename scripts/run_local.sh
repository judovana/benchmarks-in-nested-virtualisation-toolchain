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

JDK_DIR=$1
JDK_NAME=`basename $2`
COUNTER=$3
rm -rf $SCRIPT_ORIGIN/../local_workspace
mkdir $SCRIPT_ORIGIN/../local_workspace
export WORKSPACE=$SCRIPT_ORIGIN/../local_workspace
RESULT_DIR="$SCRIPT_ORIGIN/../local_results"
pushd $WORKSPACE
#mkdir -p $RESULT_DIR

mkdir $SCRIPT_ORIGIN/../local_results || true
mkdir $SCRIPT_ORIGIN/../local_results/${JDK_NAME} || true
mkdir $SCRIPT_ORIGIN/../local_results/${JDK_NAME}/${COUNTER}

ls -l $WORKSPACE > $RESULT_DIR/${JDK_NAME}/${COUNTER}/jdk.txt
uname -a > $RESULT_DIR/${JDK_NAME}/${COUNTER}/uname_output.txt
cat /proc/cpuinfo > $RESULT_DIR/${JDK_NAME}/${COUNTER}/cpuinfo_output.txt
cat /proc/meminfo > $RESULT_DIR/${JDK_NAME}/${COUNTER}/meminfo_output.txt
cat /etc/redhat-release > $RESULT_DIR/${JDK_NAME}/${COUNTER}/redhat_release_output.txt

rm -rf $WORKSPACE/rpms
mkdir $WORKSPACE/rpms
cp $JDK_DIR/$JDK_NAME $WORKSPACE/rpms
# run script swt as EXECUTED_SCRIPT in config
sh $(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")
cp -r $WORKSPACE/results $SCRIPT_ORIGIN/../local_results/${JDK_NAME}/${COUNTER}/
rm -rfv $WORKSPACE


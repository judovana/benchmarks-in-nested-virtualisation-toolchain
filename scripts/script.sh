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

WORKSPACE=/mnt/workspace
RESULT_DIR="$WORKSPACE/out"
pushd $WORKSPACE
mkdir -p $RESULT_DIR
ls -l $WORKSPACE/in/ > $RESULT_DIR/jdk.txt
uname -a > $RESULT_DIR/uname_output.txt
cat /proc/cpuinfo > $RESULT_DIR/cpuinfo_output.txt
cat /proc/meminfo > $RESULT_DIR/meminfo_output.txt
cat /etc/redhat-release > $RESULT_DIR/redhat_release_output.txt

JDK=`basename $1`
rm -rf /mnt/workspace/rpms
mkdir /mnt/workspace/rpms

MIDDLE_POINT=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep MIDDLE_POINT | sed "s/.*=//")
rm -rf $MIDDLE_POINT
mkdir $MIDDLE_POINT
cp $WORKSPACE/in/$JDK /$MIDDLE_POINT
cp $MIDDLE_POINT/$JDK /mnt/workspace/rpms
# run script swt as EXECUTED_SCRIPT in config
sh $(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")


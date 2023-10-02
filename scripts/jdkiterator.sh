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

set -x

#this folder is used as a gather point for things that need to be copied from host into VM/container
MIDDLE_POINT=$(cat $SCRIPT_ORIGIN/../config | grep ^MIDDLE_POINT= | sed "s/.*=//")
if [ "x$MIDDLE_POINT" == "x" ] ; then
  MIDDLE_POINT=$HOME/middle_point
  echo "#try not to commit the middle_point line unless you really wish" >> $SCRIPT_ORIGIN/../config
  echo "MIDDLE_POINT=$MIDDLE_POINT" >> $SCRIPT_ORIGIN/../config
fi

set -eo pipefail

#get path of folder containing JDKs from config
JDK_DIR=$(cat $SCRIPT_ORIGIN/../config | grep ^JDK_DIR= | sed "s/.*=//")
#get how many times will the selected benchmark run on each JDK in JDK_DIR
ITER_NUM=$(cat $SCRIPT_ORIGIN/../config | grep ^ITER_NUM= | sed "s/.*=//")

JDKS=`find  $JDK_DIR -type f | sort -V`
RUN_TYPE=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep ^RUN_TYPE= | sed "s/.*=//")
export DEV=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep ^DEV= | sed "s/.*=//")

if [ "x$RUN_TYPE" == "xcontainer" ]; then
        sh $SCRIPT_ORIGIN/prepare_container.sh False
fi

for jdk in $JDKS ; do
  if [ "x$RUN_TYPE" == "xcontainer" ]; then
        sh $SCRIPT_ORIGIN/add_jdk_to_prepared_container.sh `readlink -f $jdk`
  fi
  for x in `seq 1 $ITER_NUM` ; do
    if [ "x$RUN_TYPE" == "xtrue" ]; then
        sh $SCRIPT_ORIGIN/run_on_nested_VM.sh $x `readlink -f $jdk` False
    elif [ "x$RUN_TYPE" == "xfalse" ]; then
        sh $SCRIPT_ORIGIN/run_on_VM.sh $x `readlink -f $jdk`
    elif [ "x$RUN_TYPE" == "xcontainer" ]; then
        sh $SCRIPT_ORIGIN/run_from_prepared_container.sh $x `readlink -f $jdk`
    elif [ "x$RUN_TYPE" == "xcont_in_VM" ]; then
        sh $SCRIPT_ORIGIN/run_on_nested_VM.sh $x `readlink -f $jdk` True
    else
        sh $SCRIPT_ORIGIN/run_local.sh $JDK_DIR `readlink -f $jdk` $x
    fi
  done
done

if [ "x$RUN_TYPE" == "xcontainer" ]; then
        podman rmi -a -f
fi

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

JDK_DIR=$(cat $SCRIPT_ORIGIN/../config | grep JDK_DIR | sed "s/.*=//")
ITER_NUM=$(cat $SCRIPT_ORIGIN/../config | grep ITER_NUM | sed "s/.*=//")

JDKS=`find  $JDK_DIR -type f | sort -V`
for jdk in $JDKS ; do
  for x in `seq 1 $ITER_NUM` ; do
    # DEV=halt sh $SCRIPT_ORIGIN/run_on_VM.sh $x `readlink -f $jdk`
    DEV=true sh $SCRIPT_ORIGIN/run_on_nested_VM $x `readlink -f $jdk`
  done
done

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

JDK=$2
JDK_NAME=`basename ${JDK}`
COUNTER=$1

WORKSPACE=$SCRIPT_ORIGIN/../local_workspace
cd $WORKSPACE
mkdir $WORKSPACE/../container-results || true
mkdir $WORKSPACE/../container-results/${JDK_NAME} || true
RESULT_DIR=$WORKSPACE/../container-results/${JDK_NAME}/${COUNTER}
mkdir $RESULT_DIR

podman ps -all
podman run --name running-cont-run-uname preparation-cont-jdk uname -a > $RESULT_DIR/uname_output.txt
podman run --name running-cont-run-cpuinfo preparation-cont-jdk cat /proc/cpuinfo > $RESULT_DIR/cpuinfo_output.txt
podman run --name running-cont-run-meminfo preparation-cont-jdk cat /proc/meminfo > $RESULT_DIR/meminfo_output.txt
podman run --name running-cont-run-rri preparation-cont-jdk cat /etc/redhat-release > $RESULT_DIR/redhat_release_output.txt
# container alwways gots hostname same as its name, misusing this for radargun which is trying to connect to results
finalContainerName=results
podman run --name $finalContainerName preparation-cont-jdk sh $(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")
podman ps -all
podman cp $finalContainerName:/results $WORKSPACE/../container-results/${JDK_NAME}/${COUNTER}
podman rm $finalContainerName

echo --------------------------------------------------------------------------------------
echo 									RUN FINISHED									
echo --------------------------------------------------------------------------------------

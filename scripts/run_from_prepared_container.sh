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
mkdir $WORKSPACE/../container-results/${JDK_NAME}/${COUNTER}

podman ps -all
podman run --name running-cont-run preparation-cont-jdk sh $(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")
podman ps -all
podman cp running-cont-run:/results $WORKSPACE/../container-results/${JDK_NAME}/${COUNTER}
podman rm running-cont-run

echo --------------------------------------------------------------------------------------
echo 									RUN FINISHED									
echo --------------------------------------------------------------------------------------

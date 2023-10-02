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

JDK=$1
JDK_NAME=`basename ${JDK}`
echo $JDK

#WORKSPACE=/mnt/workspace
ls -l /mnt/workspace
ls -l $WORKSPACE
CONT_WORKSPACE=$SCRIPT_ORIGIN/../local_workspace
ls -l $CONT_WORKSPACE
cd $CONT_WORKSPACE
cp $WORKSPACE/in/$JDK_NAME $CONT_WORKSPACE

JDK_dockerfile=JDK_dockerfile
rm -rf $JDK_dockerfile
echo 'FROM preparation-cont' >> $JDK_dockerfile
echo "RUN rm -rf rpms" >> $JDK_dockerfile
echo "RUN mkdir /rpms || true" >> $JDK_dockerfile
echo "COPY $JDK_NAME /rpms" >> $JDK_dockerfile

podman build --tag preparation-cont-jdk -f ./$JDK_dockerfile

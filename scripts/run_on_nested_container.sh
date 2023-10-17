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
JDK_NAME=`basename ${JDK}`

#get path of folder containing JDKs from config
JDK_DIR=$(cat $SCRIPT_ORIGIN/../config | grep ^JDK_DIR= | sed "s/.*=//")

## cleaning any existing podman images and containers
podman rmi -a -f
podman rm -a -f
podman ps -all
podman images

## create local workspace
rm -rf $SCRIPT_ORIGIN/../cont_in_cont_workspace
mkdir $SCRIPT_ORIGIN/../cont_in_cont_workspace
HOST_CONT_WORKSPACE=$SCRIPT_ORIGIN/../cont_in_cont_workspace
echo finished-creating-local-workspace

## copy files necessary for benchmarking
cd $HOST_CONT_WORKSPACE
cp -r $SCRIPT_ORIGIN $HOST_CONT_WORKSPACE
cp -r /mnt/shared/TckScripts $HOST_CONT_WORKSPACE
cp -r /mnt/shared/testsuites $HOST_CONT_WORKSPACE
cp $SCRIPT_ORIGIN/../config $HOST_CONT_WORKSPACE
cp $JDK_DIR/$JDK_NAME $HOST_CONT_WORKSPACE
echo finished-copying-files-into-upcoming-container-workspace

## create the dockerfile for creating the base 
host_preparation_dockerfile=host_preparation_dockerfile
FEDORA_VERSION=$(cat $SCRIPT_ORIGIN/../config | grep ^MAINVM= | sed "s/.*=//")

echo "FROM $FEDORA_VERSION" >> $host_preparation_dockerfile

echo "RUN mkdir /local_workspace || true" >> $host_preparation_dockerfile
echo "RUN mkdir /local_workspace/local_workspace || true" >> $host_preparation_dockerfile
echo "RUN mkdir -p /home/tester/diplomka/JDKs/8 || true" >> $host_preparation_dockerfile
echo "RUN mkdir /results || true" >> $host_preparation_dockerfile

echo "COPY TckScripts /mnt/shared/TckScripts" >> $host_preparation_dockerfile
echo "COPY scripts /local_workspace/scripts" >> $host_preparation_dockerfile
#improve so only the current benchmark gets copied?
echo "COPY testsuites /mnt/shared/testsuites" >> $host_preparation_dockerfile
echo "COPY config /local_workspace" >> $host_preparation_dockerfile
echo "COPY $JDK_NAME /home/tester/diplomka/JDKs/8" >> $host_preparation_dockerfile

echo "RUN ls -l /home/tester/diplomka/JDKs/8" >> $host_preparation_dockerfile
echo "RUN ls -l /local_workspace" >> $host_preparation_dockerfile
echo "RUN ls -l /" >> $host_preparation_dockerfile
echo "RUN pwd " >> $host_preparation_dockerfile

echo 'RUN dnf -y install podman' >> $host_preparation_dockerfile

echo finished-creating-host-prep-dockerfile

podman build --tag host-preparation-cont -f ./$host_preparation_dockerfile

podman run --privileged --name prepared-base-cont-with-jdk host-preparation-cont sh /local_workspace/scripts/create_container_on_container_or_VM.sh $COUNTER $JDK False



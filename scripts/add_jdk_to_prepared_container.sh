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
#ls -l /mnt/workspace
ls -l $WORKSPACE
CONT_WORKSPACE=$SCRIPT_ORIGIN/../local_workspace
ls -l $CONT_WORKSPACE
cd $CONT_WORKSPACE
JDK_DIR=$3
cp $JDK_DIR/$JDK_NAME $CONT_WORKSPACE
cp $SCRIPT_ORIGIN/../config $CONT_WORKSPACE
cp -r $SCRIPT_ORIGIN/../vagrantfiles $CONT_WORKSPACE

VM_in_cont=$2
JDK_dockerfile=JDK_dockerfile
rm -rf $JDK_dockerfile
echo 'FROM preparation-cont' >> $JDK_dockerfile

if [ "x$VM_in_cont" == "xTrue" ]; then
  echo "RUN rm -rf $JDK_DIR" >> $JDK_dockerfile
  echo "RUN mkdir -p $JDK_DIR || true" >> $JDK_dockerfile
  echo "RUN mkdir /test/vagrantfiles || true" >> $JDK_dockerfile
  echo "COPY $JDK_NAME $JDK_DIR" >> $JDK_dockerfile
  echo "COPY config /test" >> $JDK_dockerfile
  echo "COPY vagrantfiles /test/vagrantfiles" >> $JDK_dockerfile
  echo "RUN mkdir -p /root/.ssh || true" >> $JDK_dockerfile
  echo "COPY /TckScripts/ssh-keys/priv-keys/tester_rsa /root/.ssh" >> $JDK_dockerfile
  echo "RUN sh /test/scripts/create_private_key_symlink.sh" >> $JDK_dockerfile
  echo "RUN sh /test/scripts/install_components.sh" >> $JDK_dockerfile
else
  echo "RUN rm -rf rpms" >> $JDK_dockerfile
  echo "RUN mkdir /rpms || true" >> $JDK_dockerfile
  echo "COPY $JDK_NAME /rpms" >> $JDK_dockerfile
fi

podman build --tag preparation-cont-jdk -f ./$JDK_dockerfile

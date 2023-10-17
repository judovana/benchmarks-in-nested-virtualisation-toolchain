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
SCRIPT_RUN_FROM_CONTAINER=$3
TOP_LEVEL_HOST=$(cat $SCRIPT_ORIGIN/../config | grep ^TOP_LEVEL_HOST= | sed "s/.*=//")

WORKSPACE=$SCRIPT_ORIGIN/../local_workspace
cd $WORKSPACE

#Name folders according to situation
if [ "x$SCRIPT_RUN_FROM_CONTAINER" == "xTrue" ] ; then
  mkdir $WORKSPACE/../nested-container-results || true
  mkdir $WORKSPACE/../nested-container-results/${JDK_NAME} || true
  RESULT_DIR=$WORKSPACE/../nested-container-results/${JDK_NAME}/${COUNTER}
  mkdir $RESULT_DIR
else
  mkdir $WORKSPACE/../container-results || true
  mkdir $WORKSPACE/../container-results/${JDK_NAME} || true
  RESULT_DIR=$WORKSPACE/../container-results/${JDK_NAME}/${COUNTER}
  mkdir $RESULT_DIR
fi

podman ps -all
podman run --rm --name running-cont-run-uname preparation-cont-jdk uname -a > $RESULT_DIR/uname_output.txt
podman run --rm --name running-cont-run-cpuinfo preparation-cont-jdk cat /proc/cpuinfo > $RESULT_DIR/cpuinfo_output.txt
podman run --rm --name running-cont-run-meminfo preparation-cont-jdk cat /proc/meminfo > $RESULT_DIR/meminfo_output.txt
podman run --rm --name running-cont-run-rri preparation-cont-jdk cat /etc/redhat-release > $RESULT_DIR/redhat_release_output.txt
SCRIPT=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")
GUI_PART=""
if echo ${SCRIPT} | grep J2DBench ; then
  if [ "x$DISPLAY" = "x" ] ; then
    echo "no DISPLAY!!!"
    exit 12
  fi
  echo "DISPLAY=$DISPLAY"
  xhost +"local:podman@" #<- normal user !!! mandatory
  GUI_PART="-v /tmp/.X11-unix:/tmp/.X11-unix:ro -e \"DISPLAY\" --security-opt label=type:container_runtime_t "
fi
# container alwways gots hostname same as its name, misusing this for radargun which is trying to connect to results
finalContainerName=results
#run selected script on container
podman run $GUI_PART --name $finalContainerName preparation-cont-jdk sh ${SCRIPT}
podman ps -all

ls -l $RESULT_DIR
if [ "x$SCRIPT_RUN_FROM_CONTAINER" == "xTrue" ] ; then
  #install tools that are necessary for getting results out
  dnf -y install rsync openssh-server openssh-clients
  #MIDDLE_POINT is a folder on real host that is used to collect results from individual runs
  MIDDLE_POINT=$(cat $SCRIPT_ORIGIN/../config | grep ^MIDDLE_POINT= | sed "s/.*=//")
  #setup private key for connecting to host
  mkdir -p /root/.ssh
  cp /mnt/shared/TckScripts/ssh-keys/priv-keys/tester_rsa $HOME/.ssh
  chmod 600 $HOME/.ssh/tester_rsa
  chmod 700 $HOME/.ssh
  rsync -av -e "ssh -o StrictHostKeyChecking=no -i $HOME/.ssh/tester_rsa"  --progress --exclude .git --mkpath $RESULT_DIR/ tester@$TOP_LEVEL_HOST:$MIDDLE_POINT/${JDK_NAME}/${COUNTER}
fi

podman rm $finalContainerName

echo --------------------------------------------------------------------------------------
echo 									RUN FINISHED									
echo --------------------------------------------------------------------------------------

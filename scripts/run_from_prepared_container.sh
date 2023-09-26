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
TOP_LEVEL_HOST=$(cat $SCRIPT_ORIGIN/../config | grep ^TOP_LEVEL_HOST= | sed "s/.*=//")

WORKSPACE=$SCRIPT_ORIGIN/../local_workspace
cd $WORKSPACE
mkdir $WORKSPACE/../container-results || true
mkdir $WORKSPACE/../container-results/${JDK_NAME} || true
RESULT_DIR=$WORKSPACE/../container-results/${JDK_NAME}/${COUNTER}
mkdir $RESULT_DIR

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
podman run $GUI_PART --name $finalContainerName preparation-cont-jdk sh ${SCRIPT}
podman ps -all
podman cp $finalContainerName:/results $WORKSPACE/../container-results/${JDK_NAME}/${COUNTER}
ls -l $RESULT_DIR

if [ "x$3" == "xTrue" ] ; then
  FINAL_DEST=/home/tester/diplomka/containers_in_vm_results
  ssh -o StrictHostKeyChecking=no tester@$TOP_LEVEL_HOST "mkdir -p $FINAL_DEST"
  rsync -av -e "ssh -o StrictHostKeyChecking=no" --progress --exclude .git $WORKSPACE/../container-results/${JDK_NAME}/${COUNTER} tester@$TOP_LEVEL_HOST:$FINAL_DEST/${JDK_NAME}/
fi

podman rm $finalContainerName

echo --------------------------------------------------------------------------------------
echo 									RUN FINISHED									
echo --------------------------------------------------------------------------------------

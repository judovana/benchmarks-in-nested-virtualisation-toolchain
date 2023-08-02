#!/bin/bash

CONTAINER_PATH=/home/tester/diplomka/test-docker
cd $CONTAINER_PATH

JDK=$2
JDK_NAME=`basename ${JDK}`
COUNTER=$1

mkdir $CONTAINER_PATH/../container-results || true
mkdir $CONTAINER_PATH/../container-results/${JDK_NAME} || true
mkdir $CONTAINER_PATH/../container-results/${JDK_NAME}/${COUNTER}

#while true ; do
podman ps -all
podman run --name running-cont-run preparation-cont-jdk sh $(cat /home/tester/diplomka/benchmarks-in-nested-virtualisation-toolchain/config | grep -v "^#" | grep EXECUTED_SCRIPT | sed "s/.*=//")
podman ps -all
podman cp running-cont-run:/results $CONTAINER_PATH/../container-results/${JDK_NAME}/${COUNTER}
podman rm running-cont-run
#done

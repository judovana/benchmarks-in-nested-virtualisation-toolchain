#!/bin/bash

#JDK_PATH=/home/tester/diplomka/JDKs/8/java-1.8.0-openjdk-jdk8u122.b01-0.ojdk8~u~upstream.hotspot.release.sdk.el7.x86_64.tarxz
#JDK_NAME=`basename $JDK_PATH`
JDK=$1
JDK_NAME=`basename ${JDK}`

cd /home/tester/diplomka/test-docker
rm -rf JDK_dockerfile
echo 'FROM preparation-cont' >> JDK_dockerfile
cp $JDK /home/tester/diplomka/test-docker
echo "RUN rm -rf rpms" >> JDK_dockerfile
echo "RUN mkdir /rpms || true" >> JDK_dockerfile
echo "COPY $JDK_NAME /rpms" >> JDK_dockerfile

podman build --tag preparation-cont-jdk -f ./JDK_dockerfile

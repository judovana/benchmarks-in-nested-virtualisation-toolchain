#!/bin/bash

JDK_PATH=/home/tester/diplomka/JDKs/8/java-1.8.0-openjdk-jdk8u122.b01-0.ojdk8~u~upstream.hotspot.release.sdk.el7.x86_64.tarxz
JDK_NAME=`basename $JDK_PATH`
podman ps -all
podman images
#podman image prune -all
podman rmi -a -f
podman ps -all
podman images

echo pwd1
rm -rf /home/tester/diplomka/test-docker
mkdir /home/tester/diplomka/test-docker || true && cd /home/tester/diplomka/test-docker
echo pwd2
rm -rf preparation_dockerfile
echo 'FROM fedora:36' >> preparation_dockerfile
echo 'RUN dnf -y install bc xz /usr/bin/scp which /usr/bin/find && dnf clean all' >> preparation_dockerfile
echo "RUN mkdir /test || true" >> preparation_dockerfile
echo "RUN mkdir /results || true" >> preparation_dockerfile
echo "RUN mkdir /results/fldr || true" >> preparation_dockerfile
#echo "RUN mkdir /test/TckScripts || true" >> preparation_dockerfile
echo "RUN mkdir /mnt/shared || true" >> preparation_dockerfile
echo "RUN mkdir /mnt/shared/testsuites || true" >> preparation_dockerfile
echo "RUN mkdir /mnt/shared/TckScripts || true" >> preparation_dockerfile
echo 'RUN mkdir /test/scripts || true' >> preparation_dockerfile
echo 'RUN mkdir /test/JDK || true' >> preparation_dockerfile
#echo "RUN rm -rf rpms" >> preparation_dockerfile
#echo "RUN mkdir /rpms || true" >> preparation_dockerfile

echo pwd4
cp -r /home/tester/diplomka/benchmarks-in-nested-virtualisation-toolchain/scripts /home/tester/diplomka/test-docker
#cp $JDK_PATH /home/tester/diplomka/test-docker
cp -r /mnt/shared/TckScripts /home/tester/diplomka/test-docker
cp -r /mnt/shared/testsuites /home/tester/diplomka/test-docker

#echo "COPY $JDK_NAME /rpms" >> preparation_dockerfile
echo "COPY TckScripts /mnt/shared/TckScripts" >> preparation_dockerfile
echo "COPY scripts /test/scripts" >> preparation_dockerfile
#improve so only the current benchmark gets copied?
echo "COPY testsuites /mnt/shared/testsuites" >> preparation_dockerfile
#echo "RUN tar -xf /rpms/$JDK_NAME -C /rpms" >> Dockerfile

echo "RUN ls -l /mnt/shared" >> preparation_dockerfile
echo "RUN ls -l /mnt/shared/testsuites" >> preparation_dockerfile
echo "RUN ls -l /mnt/shared/TckScripts" >> preparation_dockerfile
echo "RUN ls -l /test" >> preparation_dockerfile
echo "RUN ls -l /" >> preparation_dockerfile
#echo "RUN /rpms/j2sdk-image/bin/java -version " >> Dockerfile
echo "RUN pwd " >> preparation_dockerfile
#adding execution permission
#echo "RUN chmod +x /test/scripts/install_components.sh" >> Dockerfile

podman build --tag preparation-cont -f ./preparation_dockerfile 

echo konfec


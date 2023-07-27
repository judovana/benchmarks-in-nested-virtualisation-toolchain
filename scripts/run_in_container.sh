#!/bin/bash

JDK_PATH=/home/tester/diplomka/JDKs/8/java-1.8.0-openjdk-jdk8u122.b01-0.ojdk8~u~upstream.hotspot.release.sdk.el7.x86_64.tarxz
JDK_NAME=`basename $JDK_PATH`
podman ps -all
#podman image prune -all
podman rm -a -f
podman ps -all

echo pwd1
mkdir /home/tester/diplomka/test-docker || true && cd /home/tester/diplomka/test-docker
echo pwd2
rm -rf Dockerfile
echo 'FROM fedora:35' >> Dockerfile
echo 'RUN dnf -y install bc xz /usr/bin/scp which /usr/bin/find && dnf clean all' >> Dockerfile
echo "RUN mkdir /test || true" >> Dockerfile
echo "RUN mkdir /results || true" >> Dockerfile
echo "RUN mkdir /results/fldr || true" >> Dockerfile
echo "RUN mkdir /test/TckScripts || true" >> Dockerfile
echo "RUN mkdir /mnt/shared || true" >> Dockerfile
echo "RUN mkdir /mnt/shared/testsuites || true" >> Dockerfile
echo 'RUN mkdir /test/scripts || true' >> Dockerfile
echo 'RUN mkdir /test/JDK || true' >> Dockerfile
echo "RUN rm -rf rpms" >> Dockerfile
echo "RUN mkdir /rpms || true" >> Dockerfile

echo pwd4
cp -r /home/tester/diplomka/benchmarks-in-nested-virtualisation-toolchain/scripts /home/tester/diplomka/test-docker
cp $JDK_PATH /home/tester/diplomka/test-docker
cp -r /mnt/shared/TckScripts /home/tester/diplomka/test-docker
cp -r /mnt/shared/testsuites /home/tester/diplomka/test-docker
echo "COPY $JDK_NAME /rpms" >> Dockerfile
echo "COPY TckScripts /test/TckScripts" >> Dockerfile
echo "COPY scripts /test/scripts" >> Dockerfile
echo "COPY testsuites /mnt/shared/testsuites" >> Dockerfile
#echo "RUN tar -xf /rpms/$JDK_NAME -C /rpms" >> Dockerfile

echo "RUN ls -l /mnt/shared" >> Dockerfile
echo "RUN ls -l /mnt/shared/testsuites" >> Dockerfile
echo "RUN ls -l /test" >> Dockerfile
echo "RUN ls -l /" >> Dockerfile
#echo "RUN /rpms/j2sdk-image/bin/java -version " >> Dockerfile
echo "RUN pwd " >> Dockerfile 
#adding execution permission
#echo "RUN chmod +x /test/scripts/install_components.sh" >> Dockerfile

#echo "RUN sudo dnf install -y gcc libvirt libvirt-devel libxml2-devel make ruby-devel libguestfs-tools tree" >> Dockerfile
echo "RUN ls -l /rpms" >> Dockerfile
echo "RUN sh /test/TckScripts/jenkins/benchmarks/dacapo.sh || true" >> Dockerfile 
#echo "RUN tree" >> Dockerfile 
echo "RUN ls -l /" >> Dockerfile
echo "RUN whoami" >> Dockerfile
echo "RUN scp -r -o StrictHostKeyChecking=no  /results  tester@10.43.7.171:/home/tester/diplomka/copy-contest/" >> Dockerfile
echo 'ENTRYPOINT /bin/sh' >> Dockerfile
echo pwd5

#podman build --no-cache --tag fedora:test3 -f ./Dockerfile
podman ps -all
#podman build --no-cache -v /home/tester/diplomka/test-docker/shared-folder:/shared-folder:rw --tag fedora:test3 -f ./Dockerfile
podman build --no-cache --tag fedora:test3 -f ./Dockerfile
podman ps -all
podman cp test3:/results /home/tester/diplomka/copy-contest
echo pwd6
#podman create -it fedora:test3 /bin/sh
podman run --name test3 --rm localhost/fedora:test3 /test/JDK/j2sdk-image/bin/java -version
echo pwd7
#podman exec -it 07947900d87ed000c381f3b63b08e1477f5daa4c8fab98b2efccf349141d2338 /test/JDK/j2sdk-image/bin/java -version
echo konrec


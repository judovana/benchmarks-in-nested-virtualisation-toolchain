#!/bin/bash
set -exo pipefail
WORKSPACE=/mnt/workspace
RESULT_DIR="$WORKSPACE/out"
pushd $WORKSPACE
mkdir -p $RESULT_DIR
ls -l $WORKSPACE/in/ > $RESULT_DIR/jdk.txt
uname -a > $RESULT_DIR/uname_output.txt
cat /proc/cpuinfo > $RESULT_DIR/cpuinfo_output.txt
cat /proc/meminfo > $RESULT_DIR/meminfo_output.txt
cat /etc/redhat-release > $RESULT_DIR/redhat_release_output.txt
JDK=`basename $1`
rm -rf jdk
mkdir jdk
pushd jdk
  tar -xf $WORKSPACE/in/$JDK --strip-components=1 
popd
./jdk/bin/java -version 
./jdk/bin/java -version > $RESULT_DIR/javao
./jdk/bin/java -version 2> $RESULT_DIR/javae

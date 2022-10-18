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
JDK_UNPACKED="$HOME/jdk"
rm -rvf "$JDK_UNPACKED"
mkdir "$JDK_UNPACKED"
pushd "$JDK_UNPACKED"
  tar -xf $WORKSPACE/in/$JDK --strip-components=1 
popd
ls -l "$JDK_UNPACKED" >> $RESULT_DIR/jdk.txt

"$JDK_UNPACKED"/bin/java -version 
"$JDK_UNPACKED"/bin/java -version > $RESULT_DIR/javao
"$JDK_UNPACKED"/bin/java -version 2> $RESULT_DIR/javae



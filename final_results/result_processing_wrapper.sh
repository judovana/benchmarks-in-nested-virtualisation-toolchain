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

RESULT_DIR=$REPO_DIR/final_results
SCRIPT_DIR=$REPO_DIR/final_results # todo, move them both: s$REPO_DIR/cripts

JDK_ver=$1
benchmark=$2
if [[ $benchmark == "" ]];then
  benchmark="DACAPO J2DBENCH JMH RADARGUNs1" # TODO, ADD ALL
fi

RESULTS=`find  $RESULT_DIR -maxdepth 2 -mindepth 2 -type d`

if [[ $JDK_ver == "8" ]];then
  REGEX="java-1.8.0"
elif [[ $JDK_ver == "11" ]];then
  REGEX="java-11"
elif [[ $JDK_ver == "17" ]];then
  REGEX="java-17"
else
  echo $JDK_ver
  echo "invalid java version, running 1.8.0 as a default"
  REGEX="java-1.8.0"
fi

for res in $RESULTS ; do
  echo $res
  echo $REGEX
  echo $benchmark
  if [[ ($res == *"DACAPO"*) && ($benchmark == *"DACAPO"*)]];then
    python $SCRIPT_DIR/result_processing.py "$res" "geom" "summary.txt" True $REGEX
  elif [[ ($res == *"J2DBENCH"*) && ($benchmark == *"J2DBENCH"*)]];then
    python $SCRIPT_DIR/result_processing.py "$res" "j2dbench.geom" "j2dbench.properties" True $REGEX
  elif [[ ($res == *"JMH"*) && ($benchmark == *"JMH"*)]];then
    python $SCRIPT_DIR/result_processing.py "$res" "geom" "SPECjvm2008.001.sub" True $REGEX
  elif [[ ($res == *"RADARGUNs1"*) && ($benchmark == *"RADARGUNs1"*)]];then
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.Throughput=" "stres" True $REGEX
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.Throughput=" "stres" True $REGEX
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.ResponseTimeMean" "stres" True $REGEX
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.ResponseTimeMean" "stres" True $REGEX
  else
    echo "did not find anything"
  fi
done

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
  benchmark="DACAPO J2DBENCH JMH RADARGUNs1 RADARGUNs3 SPECJBB"
fi

RESULTS=`find  $RESULT_DIR -maxdepth 2 -mindepth 2 -type d`

export HTML=true
if [ "x$HTML" == "xtrue" ] ; then
  echo "<html><head></head><body>"
fi

title1() {
  if [ "x$HTML" == "xtrue" ] ; then
    echo "<h1>"
  fi
  echo " ${@} "
  if [ "x$HTML" == "xtrue" ] ; then
    echo "</h1>"
  fi
}

title2() {
  if [ "x$HTML" == "xtrue" ] ; then
    echo "<h2>"
  fi
  echo " ${@} "
  if [ "x$HTML" == "xtrue" ] ; then
    echo "</h2>"
  fi
}

if [[ $JDK_ver == "8" ]];then
  REGEX="java-1.8.0"
elif [[ $JDK_ver == "11" ]];then
  REGEX="java-11"
elif [[ $JDK_ver == "17" ]];then
  REGEX="java-17"
elif [[ $JDK_ver == "ALL" ]];then
  REGEX="java-"
else
  title1 $JDK_ver
  echo "invalid java version, use 8, 11 or 17" >&2
  exit 1
fi



graph_parameters() {
  ##GRAPH_NAME necessary for graph naming
  ##it requires virtualisation type and benchamrk,
  ##otherwise the cahrts will overwrite each other
  ##curently it is all in top level dir of virtualisation/virutliasation_benchamrk
  ## so using that
  graph_name=$(basename ${1})
}

for res in $RESULTS ; do
  if [ "x$HTML" == "xtrue" ] ; then
    echo "<pre>"
  fi
  echo $res
  echo $REGEX
  echo $benchmark
  if [ "x$HTML" == "xtrue" ] ; then
    echo "</pre>"
  fi

  if [[ ($res == *"DACAPO"*) && ($benchmark == *"DACAPO"*)]];then   
    graph_parameters $res DACAPO
    title2 $graph_name
    python $SCRIPT_DIR/result_processing.py "$res" "geom" "summary.txt" True $REGEX $graph_name
  elif [[ ($res == *"J2DBENCH"*) && ($benchmark == *"J2DBENCH"*)]];then
    graph_parameters $res J2DBENCH
    title2 $graph_name
    python $SCRIPT_DIR/result_processing.py "$res" "j2dbench.geom" "j2dbench.properties" True $REGEX $graph_name
  elif [[ ($res == *"JMH"*) && ($benchmark == *"JMH"*)]];then
    graph_parameters $res JMH
    title2 $graph_name
    python $SCRIPT_DIR/result_processing.py "$res" "geom" "SPECjvm2008.001.sub" True $REGEX $graph_name
  elif [[ ($res == *"RADARGUNs1"*) && ($benchmark == *"RADARGUNs1"*)]];then
    graph_parameters $res RADARGUNs1
    title2 $graph_name
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.Throughput=" "stres" True $REGEX $IS_LOCAL
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.Throughput=" "stres" True $REGEX $IS_LOCAL
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.ResponseTimeMean" "stres" True $REGEX $IS_LOCAL
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.ResponseTimeMean" "stres" True $REGEX $IS_LOCAL
  elif [[ ($res == *"RADARGUNs3"*) && ($benchmark == *"RADARGUNs3"*)]];then
    graph_parameters $res RADARGUNs3
    title2 $graph_name
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.Throughput=" "stres" True $REGEX $IS_LOCAL
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.Throughput=" "stres" True $REGEX $IS_LOCAL
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.ResponseTimeMean" "stres" True $REGEX $IS_LOCAL
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.ResponseTimeMean" "stres" True $REGEX $IS_LOCAL
  elif [[ ($res == *"SPECJBB"*) && ($benchmark == *"SPECJBB"*)]];then
    graph_parameters $res SPECJBB
    title2 $graph_name
    python $SCRIPT_DIR/result_processing.py "$res" "jbb2015.result.metric.max-jOPS" "-00001.raw" True $REGEX $IS_LOCAL
    python $SCRIPT_DIR/result_processing.py "$res" "jbb2015.result.metric.critical-jOPS" "-00001.raw" True $REGEX $IS_LOCAL
  else
    echo "did not find anything" >&2
  fi
done

if [ "x$HTML" == "xtrue" ] ; then
  echo "</body>"
fi

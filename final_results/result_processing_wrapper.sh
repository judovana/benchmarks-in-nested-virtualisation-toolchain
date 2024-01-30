#!/bin/bash

#########################################
# call in some report dir (charts will be generated in it)
# redirect to some html file (will be overwritten)
# first parameter - jdk. eg 8,17 or ALL for all jdks
# second parameter - benchamrk or "set of benchmarks" (space dlimited)
#                    or ALL for all known benchmarksS
#########################################

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

# this is just for readability
RESULT_DIR=$REPO_DIR/final_results
SCRIPT_DIR=$REPO_DIR/final_results
SCRIPT_DIR_FULL=`readlink -f $SCRIPT_DIR`

if [ "x$INVERTED_RESULT_DIR" == "x" ] ; then
  # this one is enforcing append of secondary results to this dir
  # that is abs path, as we need to merge all runs to that
  export INVERTED_RESULT_DIR="`pwd`/inverted_results"
  rm -rf $INVERTED_RESULT_DIR
  mkdir $INVERTED_RESULT_DIR
fi

JDK_ver=$1
benchmark=$2
virtualisation=$3

if [[ $benchmark == "" || $benchmark == "ALL" ]];then
  benchmark="DACAPO J2DBENCH JMH RADARGUNs1 RADARGUNs3 SPECJBB"
fi

if [[ $virtualisation == "" || $virtualisation == "ALL"  ]];then
  virtualisation=".*"
fi

RESULTS=`find  $RESULT_DIR -maxdepth 2 -mindepth 2 -type d | grep "$virtualisation"`

export HTML=true
if [ "x$HTML" == "xtrue" ] ; then
  echo "<html><head></head><body>"
fi

title1() {
  if [ "x$HTML" == "xtrue" ] ; then
    echo "<h1 id='${@}'>"
  fi
  echo " ${@} "
  if [ "x$HTML" == "xtrue" ] ; then
    echo "</h1>"
  fi
}

title2() {
  if [ "x$HTML" == "xtrue" ] ; then
    echo "<h2 id='${@}'>"
  fi
  echo " ${@} "
  if [ "x$HTML" == "xtrue" ] ; then
    echo "</h2>"
  fi
}

title3() {
  if [ "x$HTML" == "xtrue" ] ; then
    echo "<h3 id='${@}'>"
  fi
  echo " ${@} "
  if [ "x$HTML" == "xtrue" ] ; then
    echo "</h3>"
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
elif [[ $JDK_ver == "" ]];then
  REGEX="java-"
else
  title1 "invalid $JDK_ver"
  echo "invalid java version, use 8, 11 or 17" >&2
  exit 1
fi

title1 "$REGEX $benchmark"
echo "<a href='#Context:'>Context at bottom</a><br/>"

PRF=passrates.properties
rm -f $PRF # to store cross-python run values of pass rates for future processing. sort | uniq it after it is finished

titles=""
graph_parameters() {
  ##GRAPH_NAME necessary for graph naming
  ##it requires virtualisation type and benchamrk,
  ##otherwise the cahrts will overwrite each other
  ##curently it is all in top level dir of virtualisation/virutliasation_benchamrk
  ## so using that
  graph_name=$(basename ${1})
  titles="$titles $(basename  $(dirname $1)):$(basename  $1)"
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
    title3 "final score"
    python $SCRIPT_DIR/result_processing.py "$res" "geom" "summary.txt" False $REGEX $graph_name
  elif [[ ($res == *"J2DBENCH"*) && ($benchmark == *"J2DBENCH"*)]];then
    graph_parameters $res J2DBENCH
    title2 $graph_name
    title3 "final score"
    python $SCRIPT_DIR/result_processing.py "$res" "j2dbench.geom" "j2dbench.properties" False $REGEX $graph_name
  elif [[ ($res == *"JMH"*) && ($benchmark == *"JMH"*)]];then
    graph_parameters $res JMH
    title2 $graph_name
    title3 "final score"
    python $SCRIPT_DIR/result_processing.py "$res" "geom" "SPECjvm2008.001.sub" False $REGEX $graph_name
  elif [[ ($res == *"RADARGUNs1"*) && ($benchmark == *"RADARGUNs1"*)]];then
    graph_parameters $res RADARGUNs1
    title2 $graph_name
    if [ "x$HTML" == "xtrue" ] ; then
      echo "<ol>"
      echo "  <li><a href='#$graph_name - throughput get'>$graph_name - throughput get</a></li>"
      echo "  <li><a href='#$graph_name - throughput put'>$graph_name - throughput put</a></li>"
      echo "  <li><a href='#$graph_name - response mean time get'>$graph_name - response mean time get</a></li>"
      echo "  <li><a href='#$graph_name - response mean time put'>$graph_name - response mean time put</a></li>"
      echo "</ol>"
    fi
    title3 "$graph_name - throughput get"
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.Throughput=" "stres" False $REGEX $graph_name
    title3 "$graph_name - throughput put"
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.Throughput=" "stres" False $REGEX $graph_name
    title3 "$graph_name - response mean time get"
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.ResponseTimeMean" "stres" True $REGEX $graph_name
    title3 "$graph_name - response mean time put"
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.ResponseTimeMean" "stres" True $REGEX $graph_name
  elif [[ ($res == *"RADARGUNs3"*) && ($benchmark == *"RADARGUNs3"*)]];then
    graph_parameters $res RADARGUNs3
    title2 $graph_name
    if [ "x$HTML" == "xtrue" ] ; then
      echo "<ol>"
      echo "  <li><a href='#$graph_name - throughput get'>$graph_name - throughput get</a></li>"
      echo "  <li><a href='#$graph_name - throughput put'>$graph_name - throughput put</a></li>"
      echo "  <li><a href='#$graph_name - response mean time get'>$graph_name - response mean time get</a></li>"
      echo "  <li><a href='#$graph_name - response mean time put'>$graph_name - response mean time put</a></li>"
      echo "</ol>"
    fi
    title3 "$graph_name - throughput get"
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.Throughput=" "stres" False $REGEX $graph_name
    title3 "$graph_name - throughput put"
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.Throughput=" "stres" False $REGEX $graph_name
    title3 "$graph_name - response mean time get"
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Get.ResponseTimeMean" "stres" True $REGEX $graph_name
    title3 "$graph_name - response mean time put"
    python $SCRIPT_DIR/result_processing.py "$res" "BasicOperations.Put.ResponseTimeMean" "stres" True $REGEX $graph_name
  elif [[ ($res == *"SPECJBB"*) && ($benchmark == *"SPECJBB"*)]];then
    graph_parameters $res SPECJBB
    title2 $graph_name
    if [ "x$HTML" == "xtrue" ] ; then
      echo "<ol>"
      echo "  <li><a href='#$graph_name - max-jops'>$graph_name - max-jops</a></li>"
      echo "  <li><a href='#$graph_name - critical jops'>$graph_name - critical jops</a></li>"
      echo "</ol>"
    fi
    title3 "$graph_name - max-jops"
    python $SCRIPT_DIR/result_processing.py "$res" "jbb2015.result.metric.max-jOPS" "-00001.raw" False $REGEX $graph_name
    title3 "$graph_name - critical jops"
    python $SCRIPT_DIR/result_processing.py "$res" "jbb2015.result.metric.critical-jOPS" "-00001.raw" False $REGEX $graph_name
  else
    echo "did not find anything" >&2
  fi
done


title1 "pass rates:"
if [ "x$HTML" == "xtrue" ] ; then
  echo "<pre>"
fi
echo "Summing up $PRF for future processing" >&2
cat $PRF | sort | uniq > $PRF.sort.uniq
cat $PRF | wc -l >&2
cat $PRF.sort.uniq
echo "sort uniq to:" >&2
cat $PRF.sort.uniq | wc -l >&2
if [ "x$HTML" == "xtrue" ] ; then
  echo "</pre>"
fi

if [ "x$HTML" == "xtrue" ] ; then
  title1 Context:
  echo "<ol>"
  echo "<ol>"
  current_title=""
  for title in $titles ; do
    future_title=`echo $title | sed "s/:.*//"`
    full_name=`echo $title | sed "s/.*://"`
    name=`echo $title | sed "s/.*_//"`
    if [ ! "$current_title" == "$future_title" ] ; then
      current_title="$future_title"
      echo "</ol>"
      echo "<li>"$future_title"</li>"
      echo "<ol>"
    fi
    echo "  <li><a href='#$full_name'>$name</a></li>"
  done
  echo "</ol>"
  echo "</ol>"
  echo "</body>"
fi



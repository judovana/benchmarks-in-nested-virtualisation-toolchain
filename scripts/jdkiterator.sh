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

set -x

#this folder is used as a gather point for things that need to be copied from host into VM/container
MIDDLE_POINT=$(cat $SCRIPT_ORIGIN/../config | grep ^MIDDLE_POINT= | sed "s/.*=//")
if [ "x$MIDDLE_POINT" == "x" ] ; then
  MIDDLE_POINT=$HOME/middle_point
  echo "#try not to commit the middle_point line unless you really wish" >> $SCRIPT_ORIGIN/../config
  echo "MIDDLE_POINT=$MIDDLE_POINT" >> $SCRIPT_ORIGIN/../config
fi

set -eo pipefail

#get path of folder containing JDKs from config
JDK_DIR=$(cat $SCRIPT_ORIGIN/../config | grep ^JDK_DIR= | sed "s/.*=//")
#get how many times will the selected benchmark run on each JDK in JDK_DIR
ITER_NUM=$(cat $SCRIPT_ORIGIN/../config | grep ^ITER_NUM= | sed "s/.*=//")

JDKS=`find  $JDK_DIR -type f | sort -V`
RUN_TYPE=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep ^RUN_TYPE= | sed "s/.*=//")
export DEV=$(cat $SCRIPT_ORIGIN/../config | grep -v "^#" | grep ^DEV= | sed "s/.*=//")

# this function was added to solve weird instabilities in nested VMs runs.
# thus it always cleans up results and will try to rerun what is missing
# it expects the hook with `continue`  in main iterator
# it is partially invalidating stability measurements, but without it we may say VM in VM had zero pass rate
# we believe the instability in VM in VM was caused by our error or wrong HW setup.
# in theory, both primary and secondary results can point to same dir
function shiftResultsIfAllowed() {
  local theJdk="${1}"
  if [ "x$SHIFT_RESULTS" == "xTrue" ]; then
    if [ "x$PRIMARY_RESULTS" == "x" ]; then
      echo "SHIFT_RESULTS is true, but PRIMARY_RESULTS are missing"
      echo "PRIMARY_RESULTS are the results with empty results (in case of nested virtualizations)"
      echo "  but those results are the ones which are compared against existence"
      exit 1
    fi
    if [ "x$SECONDARY_RESULTS" == "x" ]; then
      echo "SHIFT_RESULTS is true, but SECONDARY_RESULTS are missing"
      echo "SECONDARY_RESULTS are the results with real results"
      echo "  so should not be empty"
      exit 1
    fi
    # we will try to run forever, while there is at least something to do
    # it will have for sure unexpected consequences
    set +e
    # "remove empty dirs, recreate their placeholders, continue should do the rest"
    # "For now we have seen SECONDARY_RESULTS pretty stable,  but garbage was in PRIMARY_RESULTS"
    # "it should work even if both are identical - empties will be removed, and we have +e"
    for x in `seq 1 $ITER_NUM` ; do
      rmdir -v "$PRIMARY_RESULTS/$theJdk/$x"
      rmdir -v "$SECONDARY_RESULTS/$theJdk/$x"
    done
    for x in `seq 1 $ITER_NUM` ; do
      mkdir "$PRIMARY_RESULTS/$theJdk"
      if [[ -e "$SECONDARY_RESULTS/$theJdk/$x" ]] ; then
        mkdir "$PRIMARY_RESULTS/$theJdk/$x"
      fi
    done
 fi
}

if [ "x$RUN_TYPE" == "xcontainer" ]; then 
    sh $SCRIPT_ORIGIN/prepare_container.sh False
fi
if [ "x$RUN_TYPE" == "xVM_in_cont" ]; then
    sh $SCRIPT_ORIGIN/prepare_container.sh False
fi

for jdk in $JDKS ; do
  jdkName=`basename $jdk`
  shiftResultsIfAllowed $jdkName
  if [ "x$RUN_TYPE" == "xcontainer" ]; then
        sh $SCRIPT_ORIGIN/add_jdk_to_prepared_container.sh `readlink -f $jdk` False $JDK_DIR
  elif [ "x$RUN_TYPE" == "xVM_in_cont" ]; then
        sh $SCRIPT_ORIGIN/add_jdk_to_prepared_container.sh `readlink -f $jdk` True $JDK_DIR
  fi
  for x in `seq 1 $ITER_NUM` ; do
    if [ "x$SHIFT_RESULTS" == "xTrue" ]; then
      if [[ -e "$PRIMARY_RESULTS/$jdkName/$x" || -e "$SECONDARY_RESULTS/$jdkName/$x" ]] ; then
        continue
      fi
    fi
    if [ "x$RUN_TYPE" == "xnested_VM" ]; then
        sh $SCRIPT_ORIGIN/run_on_nested_VM.sh $x `readlink -f $jdk` False
    elif [ "x$RUN_TYPE" == "xVM" ]; then
        sh $SCRIPT_ORIGIN/run_on_VM.sh $x `readlink -f $jdk`
    elif [ "x$RUN_TYPE" == "xcontainer" ]; then
        sh $SCRIPT_ORIGIN/run_from_prepared_container.sh $x `readlink -f $jdk` False
    elif [ "x$RUN_TYPE" == "xnested_container" ]; then
        sh $SCRIPT_ORIGIN/run_on_nested_container.sh $x `readlink -f $jdk`
    elif [ "x$RUN_TYPE" == "xVM_in_cont" ]; then
        sh $SCRIPT_ORIGIN/run_VM_on_container.sh $x `readlink -f $jdk`
    elif [ "x$RUN_TYPE" == "xcont_in_VM" ]; then
        sh $SCRIPT_ORIGIN/run_on_nested_VM.sh $x `readlink -f $jdk` True
    else
        sh $SCRIPT_ORIGIN/run_local.sh $JDK_DIR `readlink -f $jdk` $x
    fi
  done
done

if [ "x$RUN_TYPE" == "xcontainer" ]; then
        podman rmi -a -f
fi

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

set -exo pipefail

# ALL or "" shoudl be understood as all in all three cases
benchmarks="DACAPO J2DBENCH JMH RADARGUNs1 RADARGUNs3 SPECJBB"
jdks="8 11 17"
# the / is needed for precission; for subdirs, use `basename` on them
virts="/local_results /vm_results /container_results /containers_in_container_results /containers_in_vm_results"

worker=${SCRIPT_ORIGIN}/result_processing_wrapper.sh

mkdir _pregenerated_reports || echo "_pregenerated_reports already exists"
pushd _pregenerated_reports

  #all jdks x all benchmarks x all virts
  dir1=allJ_allB_allV
  if [ ! -e $dir1 ] ; then
    mkdir $dir1
    pushd $dir1
      sh ${worker} ALL ALL ALL > index.html
    popd
  else
    echo  "skipping $dir1, alreadye exists"
  fi

  #all jdks x all benchmarks x virt one by one
  #all jdks x benchmarks one by one x all virts
  #jdks one by one x all benchmarks x all virts

  #all jdks x benchmarks one by one x virt one by one
  dir3=allJ_oneB_oneV
  mkdir $dir3 || echo "$dir3 already exists"
  pushd $dir3
      for bench in $benchmarks ; do
        for virt in $virts ; do
          dir2=all"_"$bench"_"`basename $virt`
          if [ ! -e $dir2 ] ; then
            mkdir $dir2
            pushd $dir2
              sh ${worker} ALL $bench $virt > index.html
            popd
          else
            echo  "skipping $dir2, alreadye exists"
          fi
        done
      done
  popd
  #jdks one by one x benchmarks one by one x all virts
  dir3=oneJ_oneB_allV
  mkdir $dir3 || echo "$dir3 already exists"
  pushd $dir3
    for jdk in $jdks ; do
      for bench in $benchmarks ; do
          dir2=jdk$jdk"_"$bench"_"all
          if [ ! -e $dir2 ] ; then
            mkdir $dir2
            pushd $dir2
              sh ${worker} $jdk $bench ALL > index.html
            popd
          else
            echo  "skipping $dir2, alreadye exists"
          fi
      done
    done
  popd

  #jdks one by one x all benchmarks x virt one by one
  dir3=oneJ_allB_oneV
  mkdir $dir3 || echo "$dir3 already exists"
  pushd $dir3
    for jdk in $jdks ; do
        for virt in $virts ; do
          dir2=jdk$jdk"_"all"_"`basename $virt`
          if [ ! -e $dir2 ] ; then
            mkdir $dir2
            pushd $dir2
              sh ${worker} $jdk ALL $virt > index.html
            popd
          else
            echo  "skipping $dir2, alreadye exists"
          fi
        done
    done
  popd

  #jdks one by one x benchamrks one by one x virt one by one
  dir3=oneJ_oneB_oneV
  mkdir $dir3 || echo "$dir3 already exists"
  pushd $dir3
    for jdk in $jdks ; do
      for bench in $benchmarks ; do
        for virt in $virts ; do
          dir2=jdk$jdk"_"$bench"_"`basename $virt`
          if [ ! -e $dir2 ] ; then
            mkdir $dir2
            pushd $dir2
              sh ${worker} $jdk $bench $virt > index.html
            popd
          else
            echo  "skipping $dir2, alreadye exists"
          fi
        done
      done
    done
  popd

indexes=`find . -mindepth 2 | grep /index.html$ | sort`
rm -rf index.html
for index in $indexes ; do
  echo "<a href='$index'>`dirname $index`</a><br/>" >> index.html
done
popd



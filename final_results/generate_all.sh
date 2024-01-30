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

set -exo pipefail

# ALL or "" shoudl be understood as all in all three cases
benchmarks="DACAPO J2DBENCH JMH RADARGUNs1 RADARGUNs3 SPECJBB"
jdks="8 11 17"
# the / is needed for precission; for subdirs, use `basename` on them
virts="/local_results /vm_results /container_results /containers_in_container_results /containers_in_vm_results"

worker=${SCRIPT_ORIGIN}/result_processing_wrapper.sh

mkdir _pregenerated_reports || echo "_pregenerated_reports already exists"
pushd _pregenerated_reports

# this one is enforcing append og secondary results to this dir
export INVERTED_RESULT_DIR="`pwd`/inverted_results"
rm -rf $INVERTED_RESULT_DIR
mkdir $INVERTED_RESULT_DIR

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
  dir3=allJ_allB_oneV
  mkdir $dir3 || echo "$dir3 already exists"
  pushd $dir3
        for virt in $virts ; do
          dir2=all"_"all"_"`basename $virt`
          if [ ! -e $dir2 ] ; then
            mkdir $dir2
            pushd $dir2
              sh ${worker} ALL ALL $virt > index.html
            popd
          else
            echo  "skipping $dir2, alreadye exists"
          fi
        done
  popd
  #all jdks x benchmarks one by one x all virts
  dir3=allJ_oneB_allV
  mkdir $dir3 || echo "$dir3 already exists"
  pushd $dir3
      for bench in $benchmarks ; do
          dir2=all"_"$bench"_"all
          if [ ! -e $dir2 ] ; then
            mkdir $dir2
            pushd $dir2
              sh ${worker} ALL $bench ALL > index.html
            popd
          else
            echo  "skipping $dir2, alreadye exists"
          fi
      done
  popd
  #jdks one by one x all benchmarks x all virts
  dir3=oneJ_allB_allV
  mkdir $dir3 || echo "$dir3 already exists"
  pushd $dir3
    for jdk in $jdks ; do
          dir2=jdk$jdk"_"all"_"all
          if [ ! -e $dir2 ] ; then
            mkdir $dir2
            pushd $dir2
              sh ${worker} $jdk ALL ALL > index.html
            popd
          else
            echo  "skipping $dir2, alreadye exists"
          fi
    done
  popd

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

  set +x
  (
    echo "<div>J - jdk, B - benchmark, V - virtualization</div>"
    echo "<div>all - all in one chart/report, one - iterated one by one</div>"
    indexes=`find . -mindepth 2 | grep /index.html$ | sort`
    echo "<ol>"
    echo "<ol>"
    current_title=""
    for index in $indexes ; do
      dir1=`dirname $index`
      name=`basename $dir1`
      dir2=`dirname $dir1`
      future_title=`basename $dir2`
      if [ ! "$current_title" == "$future_title" ] ; then
        current_title="$future_title"
        echo "</ol>"
        echo "<li>"$future_title"</li>"
        echo "<ol>"
      fi
      echo "  <li><a href='$index'>$name</a></li>"
    done
    echo "</ol>"
    echo "</ol>"
  ) > index.html


popd



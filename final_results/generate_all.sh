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

# ALL or "" should be understood as all in all three cases
benchmarks="DACAPO J2DBENCH JMH RADARGUNs1 RADARGUNs3 SPECJBB"
jdks="8 11 17"
# the / is needed for precision; for subdirs, use `basename` on them
virts="/local_results /vm_results /container_results /containers_in_container_results /containers_in_vm_results /nestedVM_results"

worker=${SCRIPT_ORIGIN}/result_processing_wrapper.sh
pworker=${SCRIPT_ORIGIN}/postProcessor.py

mkdir _pregenerated_reports || echo "_pregenerated_reports already exists"
pushd _pregenerated_reports

# this one is enforcing append og secondary results to this dir
export INVERTED_RESULT_DIR="`pwd`/inverted_results"
if [ -e $INVERTED_RESULT_DIR ] ; then
  set +x
  echo "found directory with inverted results. If you expect any regeneration, please remove it"
  echo "if it is removed, final data can not be processed, unless it is fully regenerated"
  read -p "remove?  y/n " yORn
  if [ "x$yORn" == "xy" ] ; then
    rm -rf $INVERTED_RESULT_DIR
    mkdir $INVERTED_RESULT_DIR
  fi
  set -x
else
  mkdir $INVERTED_RESULT_DIR
fi

  #all jdks x all benchmarks x all virts
  dir1=allJ_allB_allV
  if [ ! -e $dir1 ] ; then
    mkdir $dir1
    pushd $dir1
      sh ${worker} ALL ALL ALL > index.html
    popd
  else
    echo  "skipping $dir1, already exists"
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
            echo  "skipping $dir2, already exists"
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
            echo  "skipping $dir2, already exists"
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
            echo  "skipping $dir2, already exists"
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
            echo  "skipping $dir2, already exists"
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
            echo  "skipping $dir2, already exists"
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
            echo  "skipping $dir2, already exists"
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
            echo  "skipping $dir2, already exists"
          fi
        done
      done
    done
  popd

  set +x
  (
    echo "<html><body>"
    echo "<h4><a href=\"#finals\">for final results, go to bottom</a></h4>"
    echo "<div>J - jdk, B - benchmark, V - virtualization</div>"
    echo "<div>all - all in one chart/report, one - iterated one by one</div>"
    indexes=`find . -mindepth 2 | grep /index.html$ | grep -v -e "abs.*Charts" -e passratesCharts -e "rel.*Charts" | sort`
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
    echo "<h3>Final stability data:</h3>"
    finalData=`find $INVERTED_RESULT_DIR | grep "properties$" | sort`
    finalDataDirName=`basename $INVERTED_RESULT_DIR`
    echo "</ul>"
    for index in $finalData ; do
      fileName=`basename $index`
      cat $index | sort | uniq > $index.sort.uniq
      echo "  <li><a href='$finalDataDirName/$fileName.sort.uniq'>$finalDataDirName/$fileName - sorted, uniqued</a></li>"
    done
    echo "</ul>"
    echo "<h1 id="finals"> Final charts </h1>" #generated by pythons below\
    echo "<h2 id="finals-passrates"> pass rates </h2>"
    echo "<ul>"
    echo "  <li><a href='passratesCharts/index.html'>pass rates (all permutations in one file)</a></li>" 
    echo "</ul>"
    echo "<h2 id="finals-absvals"> absolute values </h2>"
    echo "<h3>the midd-way avg/geom means are permtuation order depndent, and interesting </h3>"
    echo "<ul>"
    echo "  <li><a href='absJbvCharts/index.html'>absolute values java-benchmark-virtualisation</a></li>" 
    echo "  <li><a href='absBjvCharts/index.html'>absolute values benchmark-java-virtualisation</a></li>" 
    echo "  <li><a href='absJbvNoTimeCharts/index.html'>absolute values java-benchmark-virtualisation without radarguns' time and dacapo</a></li>"
    echo "  <li><a href='absBjvNoTimeCharts/index.html'>absolute values benchmark-java-virtualisation without radarguns' time and dacapo</a></li>"
    echo "  <li><a href='absJbvOnlyTimeCharts/index.html'>absolute values java-benchmark-virtualisation only with radarguns' time and dacapo</a></li>"
    echo "  <li><a href='absBjvOnlyTimeCharts/index.html'>absolute values benchmark-java-virtualisation only with radarguns' time and dacapo</a></li>"
    echo "</ul>"
    echo "<h2 id="finals-relvals"> relative values </h2>"
    echo "<h3>the midd-way avg/geom means are permtuation order depndent, and interesting </h3>"
    echo "<ul>"
    echo "  <li><a href='relJbvCharts/index.html'>holly grail - relative values java-benchmark-virtualisation</a></li>" 
    echo "  <li><a href='relBjvCharts/index.html'>holly grail - relative values benchmark-java-virtualisation</a></li>"
    echo "  <li><a href='relJbvNoTimeCharts/index.html'>holly grail - relative values java-benchmark-virtualisation without radarguns' time and dacapo</a></li>"
    echo "  <li><a href='relBjvNoTimeCharts/index.html'>holly grail - relative values benchmark-java-virtualisation without radarguns' time and dacapo</a></li>"
    echo "  <li><a href='relJbvOnlyTimeCharts/index.html'>holly grail - relative values java-benchmark-virtualisation only with radarguns' time and dacapo</a></li>"
    echo "  <li><a href='relBjvOnlyTimeCharts/index.html'>holly grail - relative values benchmark-java-virtualisation only with radarguns' time and dacapo</a></li>"
    echo "</ul>"
    echo "  <hr>" 
    echo "  <hr>" 
    echo "</body></html>"
  ) > index.html

popd

function finalStats() {
  local DIR="$INVERTED_RESULT_DIR/../$1"
  local runId="$2"
  local preffix="$3"
  rm -rf ${DIR}
  mkdir ${DIR}
  python ${pworker} ${runId} > ${DIR}/index.html
  mv -f ${preffix}_*.png ${DIR}/
}

set -x

  if [ ! "$DO_BASE" == false ] ; then
POST_AVG=nope  finalStats passratesCharts 2 passrate
POST_AVG=false finalStats absJbvCharts 1.1 abs
POST_AVG=true  finalStats relJbvCharts 3.1 rel
POST_AVG=false finalStats absBjvCharts 1.2 abs
POST_AVG=true  finalStats relBjvCharts 3.2 rel
  else
echo "Skiped DO_BASE"
  fi
  if [ ! "$DO_SCORES" == false ] ; then
BENCH_BLACKLIST=DACAPO KEY_BLACKLIST=Time POST_AVG=false finalStats absJbvNoTimeCharts 1.1 abs
BENCH_BLACKLIST=DACAPO KEY_BLACKLIST=Time POST_AVG=true  finalStats relJbvNoTimeCharts 3.1 rel
BENCH_BLACKLIST=DACAPO KEY_BLACKLIST=Time POST_AVG=false finalStats absBjvNoTimeCharts 1.2 abs
BENCH_BLACKLIST=DACAPO KEY_BLACKLIST=Time POST_AVG=true  finalStats relBjvNoTimeCharts 3.2 rel
  else
echo "Skiped DO_SCORES"
  fi
  if [ ! "$DO_TIMES" == false ] ; then
BENCH_WHITELIST="(DACAPO|RADARGUN).*" KEY_WHITELIST="geom|Time" POST_AVG=false finalStats absJbvOnlyTimeCharts 1.1 abs
BENCH_WHITELIST="(DACAPO|RADARGUN).*" KEY_WHITELIST="geom|Time" POST_AVG=true  finalStats relJbvOnlyTimeCharts 3.1 rel
BENCH_WHITELIST="(DACAPO|RADARGUN).*" KEY_WHITELIST="geom|Time" POST_AVG=false finalStats absBjvOnlyTimeCharts 1.2 abs
BENCH_WHITELIST="(DACAPO|RADARGUN).*" KEY_WHITELIST="geom|Time" POST_AVG=true  finalStats relBjvOnlyTimeCharts 3.2 rel
  else
echo "Skiped DO_TIMES"
 fi

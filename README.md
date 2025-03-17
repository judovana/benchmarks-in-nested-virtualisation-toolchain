the final results are commited, and you can view them directly via [http://raw.githack.com](https://rawcdn.githack.com/judovana/benchmarks-in-nested-virtualisation-toolchain/e7e68fc1140f31eb277bb2bb4f3a86e9278d16d6/final_results/_pregenerated_reports/index.html#finals)
Note especially the last group, the **Final charts**
# benchmarks-in-nested-virtualisation-toolchain

This work is focusing on research how is (nested-)virtualization affecting **accuracy** of benchmarks.

Full results for jdk 8-17 can be read here: https://is.muni.cz/th/thit1/456542_final20052024-1247.pdf which is [master these of Impact of Nested Virtualization to Benchmark Accuracy](https://is.muni.cz/th/thit1/). 
JDK 21 was added later, and some quick summ up is lower in this readme.

The accuracy is calculated by several metric, but generally it changes the absolute values to relative, %, as:  
```
-((minValue / (maxValue / 100.0))-100)
```
The results then scale as 0 - benchmark have absolutely no oscillation, 100 the minimal value was 0, maximal infinity.
Note, that eg `-((5 / (10 / 100.0))-100)) = 50` thus benchmark can oscillate by 100%, which would be absolutely intolerable. Some real data then looks like `-((1000 / (1100 / 100.0))-100)=9` whcih is acceptable benchmark.

We have to split time and score values, as they were obviously inverted.
Also, mixing of jdk (first three tables) or mixing virtualisations or benchmarks, is really bad idea. But it is also a lot of tables. See  charts linked above, and in these linked below.

### Score based benchmarks - relative accuracy (without jdk21)
With score, in absolute numbers, more  would be better

|benchmark/virtualization | real hw    | con(tainer)|   VM       | con In con |  vm in vm  |  con in vm | vm in cont |
|-------------------------|------------|------------|------------|------------|------------|------------|------------|
| specjbb                 |   17       |    16      |    17      |   16       |   17.5     |    14      |    N/A     |
| jmh                     |   11       |    10      |     8      |    8       |    7       |     9      |    N/A     |
| radargun 1 node         |   16       |    20      |    16      |   19       |    4       |    14      |    N/A     |
| radargun 3 nodes        |   15       |    10      |    14      |    9       |   35       |     8      |    N/A     |
| j2dbench                |   11       |     5      |    11      |    6       |   10       |    11      |    N/A     |


### Time based benchmarks - relative accuracy (without jdk21)    
With time, in absolute numbers, the lesser would be better

|benchmark/virtualization | real hw    | con(tainer)|   VM       | con In con |  vm in vm  |  con in vm | vm in cont |
|-------------------------|------------|------------|------------|------------|------------|------------|------------|
| radargun 1 node         |   10       |   10       |   13.5     |     9      |   12       |    9       |    N/A     |
| radargun 3 nodes        |   11.5     |   10       |   12       |    12      |   15       |   15       |    N/A     |
| dacapo                  |   11       |   10       |   11       |    17      |   12       |   26       |    N/A     |

We tried  8 JDKs 1.8.0 , 8 JDKs 11, 8 JDKs 17, and 4 jdks21 (wip). Each JDK was run five times. We were not stripping worst/best runs, as there was no need for it.
Partial and detailed descriptions and results or absolute values are in the charts linked above, and in these linked below.
Radargun contains both score and time metrics. Vm in container was indeed unimplemented

With all this effort, we hit interesting new value - crash rates, because  yes, jdk can crash fro time to time. But with all those virtualisations, all the chain may crash more often.

###  Pass rates - % of successful runs from all runs (without jdk21)

|benchmark/virtualisation | real hw    | con(tainer)|   VM       | con In con |  vm in vm  |  con in vm | vm in cont |
|-------------------------|------------|------------|------------|------------|------------|------------|------------|
| specjbb                 |     90     |    90      |     90     |    90      |     100    |    90      |    N/A     |
| jmh                     |    100     |   100      |    100     |   100      |      97    |    98      |    N/A     |
| radargun 1 node         |     90     |   100      |    100     |    97      |     100    |   100      |    N/A     |
| radargun 3 nodes        |     90     |   100      |    100     |   100      |      99    |    96      |    N/A     |
| j2dbench                |     90     |   100      |     88     |    98      |     100    |    95      |    N/A     |
| dacapo                  |     91     |    98      |     85     |    40      |      80    |    66      |    N/A     |

### vm in container failure
We were unable to pass the error of:
```
 + vagrant ...
 Error while connecting to Libvirt: Error making a connection to libvirt URI qemu:///system:
 Call to virConnectOpen failed: Failed to connect socket to '/var/run/libvirt/virtqemud-sock': No such file or directory
```

The run_VM_on_container.sh do not work correctly now, and latest working revision is https://github.com/judovana/benchmarks-in-nested-virtualisation-toolchain/tree/8ecd2383e2f791555be4c5e721cc5aefc2ffdcc9

Still.. we never make VM in container to work.

### Per JDK results
|   JDK   /virtualisation | real hw    | con(tainer)|   VM       | con In con |  vm in vm  |  con in vm | vm in cont |all         |
|-------------------------|------------|------------|------------|------------|------------|------------|------------|------------|
| jdk  8                  |            |            |            |            |            |            |    N/A     |            |
| jdk 11                  |            |            |            |            |            |            |    N/A     |            |
| jdk 17                  |            |            |            |            |            |            |    N/A     |            |
| jdk 21                  |            |            |            |            |            |            |    N/A     |            |
| all                     |            |            |            |            |            |            |    N/A     |            |


|   JDK   /benchmark      | specjbb    | jmh        |radargun s1 |radargun s3 | j2dbench   | dacapo     |all
|-------------------------|------------|------------|------------|------------|------------|------------|------------|
| jdk  8                  |            |            |            |            |            |            |            |
| jdk 11                  |            |            |            |            |            |            |            |
| jdk 17                  |            |            |            |            |            |            |            |
| jdk 21                  |            |            |            |            |            |            |            |
| all                     |            |            |            |            |            |            |            |


Partial and detailed descriptions and results or absolute values are in the charts linked above, and in these linked below.
## Prerequisites for running:
1. Private key has to be present in ~/.ssh
2. The key has to be symlinked on multiple places, but the script complains correctly, so it is easy to fix.
3. scripts/install_components.sh has to be run once before running the main script (to save time in repeated launches).
4. If you wish to use VMs, prepare VM image(s) for vagrant.
5. Adjust vagrant files for host VMs and/or nested VMs acording to the used HW.
    1. The default preset CPU threads and RAM amount are OK for a machine with 32GB RAM and 8 cores/threads (or more). Change if you use a different machine, though lower parameters are not recommended, especially if you plan on using nested scenarios.
6. Adjust config:
    1. Set the OS for each of the individual virtualization levels.
    2. Set the number of iterations per JDK.
    3. Set the hostname of top-level permanent run which stores results over individual runs.
    4. Set path leading to directory containing JDK builds.
    5. Set the used benchmark runner (script launched on final environment from which `results` dir is then collected`)
    1. Set the type of virtualization scenario.
7. Start benchmarking like this: `cd .../benchmarks-in-nested-virtualisation-toolchain/scripts && nohup jdkiterator.sh > log`
    1. Don`t forget, that for J2DBench you need DISPLAY (unless it runs in full VM)
        1. I'm afraid the :0 is hardcoded as fallback on several places, although educated guess is always done first.
        2. That usually means logged in GUI session
    2. For RadarGun you may need playing with /etc/hosts in both VM and HW
    3. There is a "magical" `results` hostname, I no longer recall where it comes from (container?)


## Result processing
1. Make sure that "result_processing.py", "postProcessor.py", "generate_all.sh" and "result_processing_wrapper.sh" are placed inside final_results folder, next to folders containing results like local_results and vm_results.
2. Make sure you have python with matplotlib installed. Afaik it is python3 dialect.
3. Run like this: "sh result_processing_wrapper.sh <JDK_ver> <benchmarks>"
```
   Valid values for JDK_ver: 8, 11, 17 or ALL
   Valid values for benchmark: DACAPO J2DBENCH JMH RADARGUNs1 RADARGUNs3 SPECJBB (any subset of them is valid, default = all)
   Examples: sh result_processing_wrapper.sh                               - no parameters, generates all 
             sh result_processing_wrapper.sh 17                            - process all results from java 17
             sh result_processing_wrapper.sh 11 "DACAPO JMH RADARGUNs3"    - process results from dacapo, jmh and radargun3 from java 11
```
4. You may use `_pregenerated_reports` or run `generate_all.sh` to generate various combinations.
    1. They may seem the same, but they are not. The resulting statistics heavily differs based on input subset.

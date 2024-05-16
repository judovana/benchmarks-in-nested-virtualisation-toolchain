the final results are commited, and you can view them directly via [http://raw.githack.com](https://rawcdn.githack.com/judovana/benchmarks-in-nested-virtualisation-toolchain/d58e51a353c081504b86b2cf95b4d904408115cc/final_results/_pregenerated_reports/index.html#finals)
Note especially the last group, the **Final charts**
# benchmarks-in-nested-virtualisation-toolchain

Prerequisites for running:
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


Result processing
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

the final results are commited, and you can view them directly via [http://raw.githack.com](https://rawcdn.githack.com/judovana/benchmarks-in-nested-virtualisation-toolchain/73d8808e8cabb9c6b6955c68eca91896c2d198e8/final_results/_pregenerated_reports/index.html#finals)
Note especially the last group, the **Final charts**
# benchmarks-in-nested-virtualisation-toolchain

Prerequisites for running
1. Private key has to be present in ~/.ssh
2. The key has to be symlinked on multiple places, but the script complains correctly, so it is easy to fix.
3. scripts/install_components.sh has to be run once before running the main script (to save time in repeated launches)
4. if you wish to use VMs, prepare VM image(s) for vagrant.
5. adjsut vagrant files for main and/or nested vms acording to HW
    1.  the preset CPU and RAMs are preset for machine of aprox 16gb of ram and 8 cores/
6. adjsut config
    1. type of virtualisation
    2. used OSes xor VMs xor container
        1. only  containers are morevoer automated, others you have to preprepare
    3. directories with JDKs
    4. used benchamrk (ti: script laucnehd on final evironment which `results` dir is then collected`)
    5. hostname of top-level pernament run which stores results over individual runs
7. run is then `cd .../benchmarks-in-nested-virtualisation-toolchain/scripts && nohup jdkiterator.sh > log`
    1. dont forget, that for j2dbench you need DISPLAY (unless it runs in full VM)
        1. I'm afraid the :0 is hardcoded as fallback on several places, although educated guess is alwaysdoen first
    2. that usually means looged in gui session
    3. for RADARGUNS you may need playng with /etc/hosts in both vm and HW
    4. there is magical `results` host, I do no longer recall where it comes from (container?)


Result processing
1. Make sure that "result_processing.py" and "result_processing_wrapper.sh" are placed inside final_results folder, next to local_results and vm_results.
2. Make sure you have python with matplotlib installed. Afaik it is python3 dialect
3. Run like this: "sh result_processing_wrapper.sh <JDK_ver> <benchmarks>"
```
   Valid values for JDK_ver: 8, 11, 17 or ALL
   Valid values for benchmark: DACAPO J2DBENCH JMH RADARGUNs1 RADARGUNs3 SPECJBB (any subset of them is valid, default = all)
   Examples: sh result_processing_wrapper.sh                               - no parameters, generates all 
             sh result_processing_wrapper.sh 17                            - process all results from java 17
             sh result_processing_wrapper.sh 11 "DACAPO JMH RADARGUNs3"    - process results from dacapo, jmh and radargun3 from java 11
```
4. you may use `_pregenerated_reports` or run `genrate_all.sh` to generate various combinations.
    1. they may seem same, but are not. The resulting statistics heavily differs based on input subset

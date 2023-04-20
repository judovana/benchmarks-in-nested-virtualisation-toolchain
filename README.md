# benchmarks-in-nested-virtualisation-toolchain

Prerequisites for running
1. Private key has to be present in ~/.ssh
2. The key has to be symlinked on multiple places, but the script complains correctly, so it is easy to fix.
3. scripts/install_components.sh has to be run once before running the main script (to save time in repeated launches)

Result processing
1. Make sure that "result_processing.py" and "result_processing_wrapper.sh" are placed inside final_results folder, next to local_results and vm_results.
2. Make sure you have python with matplotlib installed
3. Run like this: "sh result_processing_wrapper.sh <JDK_ver> <benchmark>"
   Valid values for JDK_ver: 8, 11, 17 (fail if invalid parameter is entered)
   Valid values for benchmark: DACAPO J2DBENCH JMH RADARGUNs1 RADARGUNs3 SPECJBB (any subset of them is valid, default = all)
   Examples: sh result_processing_wrapper.sh                               - no parameters, FAIL
             sh result_processing_wrapper.sh 17                            - process all results from java 17
             sh result_processing_wrapper.sh 11 "DACAPO JMH RADARGUNs3"    - process results from dacapo, jmh and radargun3 from java 11

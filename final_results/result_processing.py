### This script was created as a helping tool to process results from
### Dacapo, SpecJVM2008 and SpecJBB2015. Thanks to Jiri Vanek for his
### assistance

### run as: \result_processing.py "path_to_result_folder" "key" "result_fileName" True/False(invert values)
### key is the beginning of the line in which the result in result file is (geom for dacapo)

#!/usr/bin/python2.7
import os
import sys
import matplotlib.pyplot as plt 

args = sys.argv
invert = args[4]
containsFilter=args[5]
isLocal=args[6]
runsPerJDK  = 5 ### change if needed

def calc_relative_diff(oldVal, newVal, invert):
     #newVal is 100%
     percent = round((newVal / 100.0), 3)
     old_percent = round((oldVal / percent),3)
     dif = round((old_percent - 100.0), 0)
     if not invert:
         dif = -1 * dif
         #eg old 2000, new 1500=> 133% - 100%   -33% regression
         #eg old 1500 new 2000 => 75% - 100%     25% improvement
     else:
         dif = 1 * dif
         #eg old 2000, new 1500=> 133% - 100%    33% improvement
         #eg old 1500 new 2000 => 75% - 100%    -25% regression
     return dif

def parse_number(line):
    #print("parsing number: ", line)  
    parsed_number = ""
    for char in line:
        if (char == '.'):
            parsed_number += '.'
        if not (char.isdigit() or char == '.'):
            parsed_number = ""
        elif (char.isdigit()):
            parsed_number += char
    #print("parsed number: ", parsed_number)  
    if parsed_number == "":
        return 0
    #print("rounded number: ", round(float(parsed_number)))
    return round(float(parsed_number))

def min_max_avg_med(list_, of_values):
    list_.sort()
    #to_delete = (of_values // 10)
    #print("PASSED: ", of_values, " out of 100 ", "deleting: ",  to_delete, " from top and bottom")
    #del list_[(of_values - to_delete):]
    #del list_[:to_delete]
    print("final number of values: ", len(list_))  
    result = (min(list_), max(list_), sum(list_) / len(list_), list_[len(list_) // 2])
    return result

def printer(list_of_tuples, invert):
    x=-1
    for i in range(len(list_of_tuples)):
        x=x+1
        min_ = list_of_tuples[i][0]
        max_ = list_of_tuples[i][1]
        avg_ = list_of_tuples[i][2]
        med_ = list_of_tuples[i][3]
        print(" ** ", x)
        print("MIN: ", min_)
        print("MAX: ", max_)
        print("AVG: ", avg_)
        print("MED: ", med_)
        print("Relative differences 1:")
        print("MIN-MAX: " + str(calc_relative_diff(min_, max_, invert)) + " %")
        print("MIN-AVG: " + str(calc_relative_diff(min_, avg_, invert)) + " %")
        print("MIN-MED: " + str(calc_relative_diff(min_, med_, invert)) + " %")
        print("MAX-MIN: " + str(calc_relative_diff(max_, min_, invert)) + " %")
        print("MAX-AVG: " + str(calc_relative_diff(max_, avg_, invert)) + " %")
        print("MAX-MED: " + str(calc_relative_diff(max_, med_, invert)) + " %")
        print("AVG-MED: " + str(calc_relative_diff(avg_, med_, invert)) + " %")
        print("")

###1st metric
def avgmed_alljdks_metric(path, key, result_file):
    geometric_means = []
    for root, dirs, files in os.walk(path, topdown=False):
        for name in files:
            filename = os.path.join(root, name)
            if (filename.endswith(result_file) and containsFilter in filename):
                with open(filename) as f:
                    lines = [one_line.rstrip() for one_line in f]
                for line in lines:
                    if (line.startswith(key)):
                        geometric_means.append(int(parse_number(line)))
    print("creating figure")
    # x axis values 
    y1 = geometric_means 
    # corresponding y axis values 
    x1 = range(0, len(geometric_means))
    
    # plotting the points  
    plt.plot(x1, y1) 
    
    # naming the x axis 
    plt.xlabel('run') 
    # naming the y axis 
    plt.ylabel(args[2]) 
    
    # giving a title to my graph 
    plt.title(containsFilter + isLocal) 
    
    # function to show the plot 
    print("GRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + isLocal)
    name_fig = "bery_good_" + containsFilter + "_" + isLocal + "_" + args[2] + ".png"
    plt.savefig(name_fig)
    result = []
    result.append(min_max_avg_med(geometric_means, len(geometric_means)))
    return result

###2nd metric
def avgmed_by_jdk_metric(path, key, result_file):
    geometric_means = []
    averages_per_jdk = []
    medians_per_jdk = []
    for root, dirs, files in os.walk(path, topdown=False):
        for name in files:
            filename = os.path.join(root, name)
            if (filename.endswith(result_file) and containsFilter in filename):
                #print("///////////////////////////////////////////////////////////")
                #print(os.path.abspath(name), "   ---   ", filename, "---------------------", containsFilter)
                #print("///////////////////////////////////////////////////////////")
                with open(filename) as f:
                    lines = [one_line.rstrip() for one_line in f]
                for line in lines:
                    if (line.startswith(key)):
                        geometric_means.append(int(parse_number(line)))
                        if len(geometric_means) == runsPerJDK:
                            geometric_means.sort()
                            #to_delete = (runsPerJDK // 10)
                            #del geometric_means[(runsPerJDK - to_delete):]
                            #del geometric_means[:to_delete]
                            averages_per_jdk.append(sum(geometric_means) / len(geometric_means))
                            medians_per_jdk.append(geometric_means[len(geometric_means) // 2])
                            del geometric_means[:]
    result = []
    result.append(min_max_avg_med(averages_per_jdk, len(averages_per_jdk)))
    result.append(min_max_avg_med(medians_per_jdk, len(medians_per_jdk)))
    return result

print("1st avgmed_alljdks_metric:")
print(args[0], args[1], args[2], invert)
printer(avgmed_alljdks_metric(args[1], args[2], args[3]), invert)
print("")
print("2nd avgmed_by_jdk_metric:")
#printer(avgmed_by_jdk_metric(path1, "geom", "summary.txt"), invert)
printer(avgmed_by_jdk_metric(args[1], args[2], args[3]), invert)
print("")

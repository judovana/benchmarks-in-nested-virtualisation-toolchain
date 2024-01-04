### This script was created as a helping tool to process results from
### Dacapo, SpecJVM2008 and SpecJBB2015. Thanks to Jiri Vanek for his
### assistance

### run as: \result_processing.py "path_to_result_folder" "key" "result_fileName" True/False(invert values)
### key is the beginning of the line in which the result in result file is (geom for dacapo)

#!/usr/bin/python2.7
import os
import sys
import re
import matplotlib.pyplot as plt 

args = sys.argv
invert = args[4]
containsFilter=args[5]
runType=args[6]
runsPerJDK  = 5 ### change if needed

class NvrRunValue(object):
    value = 0
    nvr = ""
    run = ""
    def __init__(self, value, nvr, run):
        self.value = value
        self.nvr = nvr
        self.run = run

def is_html():
    return os.environ.get('HTML') is not None and os.environ.get('HTML') == "true"

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def shortenNvr(val):
    val = re.sub("[^0-9]", "-", val);
    val = re.sub("-+", "-", val);
    val = re.sub("^-", "", val);
    val = re.sub("-$", "", val);
    val = re.sub("-", ".", val);
    return val;

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

def calculate_crash_rate(list_, path, JDKs_expected):
    if is_html:
        print("<pre>")
    of_runs_expected = int(re.sub("[^0-9]", "", get_num_of_iterations(path))) * JDKs_expected
    crash_rate = of_runs_expected / len(list_) 
    pass_rate = '{:.1%}'.format(len(list_)/of_runs_expected)
    print("final number of values: ", len(list_), " out of ", of_runs_expected)  
    print("Pass rate: ", pass_rate)
    if is_html:
        print("</pre>")
    return pass_rate

def min_max_avg_med(list_, of_values, path, JDKs_expected, to_print):
    list_.sort()
    #to_delete = (of_values // 10)
    #print("PASSED: ", of_values, " out of 100 ", "deleting: ",  to_delete, " from top and bottom")
    #del list_[(of_values - to_delete):]
    #del list_[:to_delete]
    if to_print == True:
        passRate=calculate_crash_rate(list_, path, JDKs_expected)
        filename = 'passrates.properties'
        if os.path.exists(filename):
            append_write = 'a' # append if already exists
        else:
            append_write = 'w' # make a new file if not
        f = open(filename,append_write)
        f.write('todoVirtualisationAndBenchmark=' + passRate + "\n")
        f.close()
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
        if is_html:
            print("<h3>")
        print(" ** ", x)
        if is_html:
            print("</h3>")
            print("<pre>")
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
        if is_html:
            print("</pre>")

def create_figure(x1, y1, x_name, y_name, name_modifier, clear_plot, figg = None):
    eprint("creating figure. x:", y1, ", y:", x1)
    print("values:", y1)
    # x axis values 
    #y1 = geometric_means 
    # corresponding y axis values 
    #x1 = range(0, len(geometric_means))

    # enabling labels rotations
    if (figg is None):
        fig = plt.figure(figsize=(max(len(x1)/5+1,5),5))
    else:
        fig = figg
    ax = plt.gca()
    # plotting the points  
    ax.plot(x1, y1) 
    
    # naming the x axis 
    plt.xlabel(x_name) 
    # naming the y axis 
    plt.ylabel(y_name) 
    
    # giving a title to my graph 
    plt.title(containsFilter + runType) 
    
    # rotate x axe labels by vertically and making room for them
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor")
    fig.subplots_adjust(top=0.9)
    fig.subplots_adjust(bottom=0.3)
    fig.tight_layout()

    # function to plot the plot 
    if (clear_plot):
        name_fig = "chart_" + containsFilter + "_" + runType + "_" + args[2] + "_" + name_modifier + ".png"
        plt.savefig(name_fig)
        file_path = os.getcwd() + "/" + name_fig
        if is_html():
            print("<br/><a href='"+file_path.strip()+"'><img src='"+file_path.strip()+"'></img></a><br/>")
        else:
            print("file: ", file_path.strip())
    if (clear_plot):
        plt.clf()
    return fig

###1st metric
def avgmed_alljdks_metric(path, key, result_file, JDKs_expected):
    geometric_means = []
    for root, dirs, files in os.walk(path, topdown=False):
        for name in files:
            filename = os.path.join(root, name)
            if (filename.endswith(result_file) and containsFilter in filename):
                with open(filename) as f:
                    lines = [one_line.rstrip() for one_line in f]
                for line in lines:
                    if (line.startswith(key)):
                        # we have to find the NVR/number parent which is always there, and is the id of run
                        runDir=root
                        run=os.path.basename(runDir)
                        while not run.isdigit():
                            runDir=os.path.dirname(runDir)
                            run=os.path.basename(runDir)
                        nvrDir=os.path.dirname(runDir)
                        nvr=os.path.basename(nvrDir)
                        nvr=shortenNvr(nvr)
                        geometric_means.append(NvrRunValue(int(parse_number(line)), nvr, run))
    x = list(map(lambda title: title.nvr+":"+title.run, geometric_means))
    create_figure(x, list(map(lambda num: num.value, geometric_means)), "run", args[2], "raw values", True)
    result = []
    result.append(min_max_avg_med(list(map(lambda num: num.value, geometric_means)), len(geometric_means), path, JDKs_expected, True))
    x = range(0, len(result[0]))
    create_figure(x, result[0], "avgmed_alljdks_metric", args[2], "1st metric", True)
    return result

###2nd metric
def avgmed_by_jdk_metric(path, key, result_file, JDKs_expected):
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
    result.append(min_max_avg_med(averages_per_jdk, len(averages_per_jdk), path, JDKs_expected, False))
    result.append(min_max_avg_med(medians_per_jdk, len(medians_per_jdk), path, JDKs_expected, False))
    create_figure(range(0, len(averages_per_jdk)), averages_per_jdk, "avg_by_jdk_metric-raw", args[2], "raw_values_averages_per_jdk", True)
    create_figure(range(0, len(medians_per_jdk)), medians_per_jdk, "med_by_jdk_metric-raw", args[2], "raw_values_medians_per_jdk", True)
    fig_transfer = create_figure(range(0, len(result[0])), result[0], "averages (blue) - rewritten", args[2], "2nd_metric_averages_per_JDK", False) #this one is not saved, and is appended by the below and thens aved.. the weird True/False is doing that
    create_figure(range(0, len(result[1])), result[1], "averages (blue) ; medians (orange)", args[2], "2nd_metric_medians_per_JDK", True, fig_transfer)
    return result

def get_num_of_iterations(path):
    file = open(path + "/../../../config").readlines()
    #default value is 5 iterations
    of_iterations = 5
    for line in file:
        if line.startswith("ITER_NUM="):
            of_iterations = line.split("=")[-1].strip()
    print ("Expected number of iterations: " + of_iterations)
    return of_iterations
    
#prerequisite: Every JDK has at least its root folder in the result folder
def get_expected_number_of_JDKs(JDK_path):
    if is_html:
        print("<pre>")
    OfJDKFiles = 0
    for file_name in os.listdir(JDK_path):
        if containsFilter in file_name:
            OfJDKFiles += 1
    print("\n")        
    print("Expected number of ", containsFilter, " JDKs: ", OfJDKFiles)
    if is_html:
        print("</pre>")
    return OfJDKFiles
        
JDKs_expected = get_expected_number_of_JDKs(args[1])
if is_html:
    print("<h4>")
print("1st avgmed_alljdks_metric:")
if is_html:
    print("</h4>")
    print("<pre>")
print(args[0], args[1], args[2], invert)
if is_html:
    print("</pre>")
printer(avgmed_alljdks_metric(args[1], args[2], args[3], JDKs_expected), invert)
print("")
if is_html:
    print("<h4>")
print("2nd avgmed_by_jdk_metric:")
if is_html:
    print("</h4>")
#printer(avgmed_by_jdk_metric(path1, "geom", "summary.txt"), invert)
printer(avgmed_by_jdk_metric(args[1], args[2], args[3], JDKs_expected), invert)
print("")

#!/bin/bash -l


#
#  Copyright (C) 2021-2023 
#     Research Computing Services (RCS)
#     Information Services & Technology
#     Boston University
# 
#  Contact: rcs@bu.edu
# 
#  For detailed copyright and licensing information, please refer to the
#  LICENSE file in the top level directory.
# 

###### How to call:
#        run_all_benchmarks.sh output_dir tmp_dir min_cores max_cores

#     output_dir:  where this will place its output file, benchmark_folder_name.csv
#                  A subfolder with a datestamp will automatically be used in output_dir
#     work_dir:  directory to use for temporary files.  This script must allow running
#               multiple copies at a time so all data files should get copied to work_dir.
#               All output (timing, log files, etc) should also go to work_dir.
#     min_cores:  minimum number of cores to use.  
#     max_cores:  maximum number of cores to use.
#     A value of -1 for both min_cores and max_cores means "run a few iterations
#     with as few cores as allowed by the benchmark as a test case"
# Master script to run all the benchmarks from this directory.

# The output is a set of CSV format files in the specified output directory.
# The output directory will be deleted if it already exists.

# Each benchmark folder needs a script called "run_bench.sh".  This
# will take one argument which is the output directory where the 
# CSV output file(s) will be copied.  The CSV output shoud be in a 
# sensible format ready to be read and plotted using Excel or related
# tools.  The CSV file should be named after the benchmark.

# Benchmarks that need multiple cores etc. to be specified will handle
# those options on their own in their run_bench.sh files.


# Before running, be sure to run "build_all_benchmarks.sh" to find all
# of the src/build.sh scripts and execute them.


OUTPUT_DIR=$1
WORK_DIR=$2
MIN_CORES=$3
MAX_CORES=$4

# What directory is this script in?
BENCH_ALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

DATESTAMP=$(date "+%Y.%m.%d-%H.%M.%S")
OUTPUT_DIR=$OUTPUT_DIR/$DATESTAMP

rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# A log file will be written in OUTPUT_DIR
LOG=$OUTPUT_DIR/run_bench_${DATESTAMP}.log
# Aggregate all output from the run_bench.sh scripts 
LOG_ALL=$OUTPUT_DIR/run_bench_${DATESTAMP}_all.log
touch $LOG $LOG_ALL


# CPU info
lscpu > $OUTPUT_DIR/lscpu.out
cat /proc/cpuinfo >  $OUTPUT_DIR/proc_cpuinfo.out

# OS info
cp /etc/os-release $OUTPUT_DIR/os-release.out


# This array defines the set of benchmarks to be run.  They must be
# the names of the subdirectories of this script where the benchmarks
# are found.
# This version has 2 benchmarks included - STREAM and "model_bench" which 
# is a descriptive example of setting up a benchmark.
declare -a ALL_BENCHMARKS=(stream model_bench)


time {
        all_start_time=`date +%s`
        for BENCH_PROG in "${ALL_BENCHMARKS[@]}"
        do
                echo Running bench $BENCH_PROG | tee -a $LOG
                start_time=`date +%s`
                cd $BENCH_ALL_DIR/$BENCH_PROG
                ./run_bench.sh $OUTPUT_DIR $WORK_DIR $MIN_CORES $MAX_CORES |& tee -a $LOG_ALL
                end_time=`date +%s`
                echo "Benchmark time (sec):" `expr $end_time - $start_time`  | tee -a $LOG
        done ;
        all_end_time=`date +%s`
        echo "Time (sec) to run all benchmarks:" `expr $all_end_time - $all_start_time`  | tee -a $LOG
} 

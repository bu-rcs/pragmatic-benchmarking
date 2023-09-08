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
#        run_bench.sh bench_root_dir output_dir tmp_dir min_cores max_cores
#
#     output_dir:  where this will place its output file, benchmark_folder_name.csv
#     work_dir:  directory to use for temporary files.  This script must allow running
#               multiple copies at a time so all data files should get copied to work_dir.
#               All output (timing, log files, etc) should also go to work_dir.
#     min_cores:  minimum number of cores to use.  
#     max_cores:  maximum number of cores to use.
#     A value of -1 for both min_cores and max_cores means "run a few iterations
#     with as few cores as allowed by the benchmark as a test case"


OUTPUT_DIR=$1
WORK_DIR=$2
MIN_CORES=$3
MAX_CORES=$4

# What's the name of this benchmark?
BENCH_NAME=model_bench
# What directory is this script in?
export BENCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# Create a subdirectory for this in WORK_DIR
mkdir -p $WORK_DIR/$BENCH_NAME


##### NOTE ####
# time is a bash shell command
# /usr/bin/time is a Linux timing command. Use this as its output is 
#   just a regular printout to stderr
 
# Do some setup of variables, etc. here if needed

# Check for special testing mode.
#  For some benchmarks, the range might be 8,12,16,20,24,28,32
#     and the run_bench.sh needs to figure out appropriate things
#     with min_cores and max_cores.  
if (( $MIN_CORES == -1 && $MAX_CORES == -1 )); then  
  # Test mode should run the program very quickly to make sure everything
  # runs and the output CSV files are generated correctly.
  echo Running $BENCH_NAME in test mode.
  MIN_CORES=1
  MAX_CORES=2
  # or MIN_CORES=4
  #    MAX_CORES=8 etc
fi

 


# just in case - unset things that could have an impact on
# testing so they can be set deliberately below
unset OMP_NUM_THREADS
unset MKL_NUM_THREADS
unset NUMBA_NUM_THREADS

# Run all of the benchmarks for all available processors.  Run out of the
# $WORK_DIR for all temp output.  Delete any previous results in case this
# is a re-run.
cd $WORK_DIR/$BENCH_NAME
rm -f $BENCH_NAME.out

# Set any environment variables necessary for running the benchmark.
# export LD_LIBRARY_PATH=$BENCH_DIR/lib:$LD_LIBRARY_PATH
# etc ...

# Use whatever loop over cores is appropriate for this benchmark.
for i in $(seq $MIN_CORES $MAX_CORES); do 
    # Run the benchmark. Here it's being externally timed but this
    # will depend on the benchmark.
    /usr/bin/time -o $BENCH_NAME.out -a  sleep 1  
    # For a "real" benchmark this would look something like:
    # $BENCH_DIR/bin/progname --data $BENCH_DIR/data ...args... >> $BENCH_NAME.out
done

 
# Just to be sure make the output directory if needed
mkdir -p $OUTPUT_DIR

#### DO SOME FILTERING AND FORMATTING
python3 $BENCH_DIR/filter.py $WORK_DIR/$BENCH_NAME/$BENCH_NAME.out > $OUTPUT_DIR/$BENCH_NAME.csv

  

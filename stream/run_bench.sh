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

# Run the scalable stream benchmark...

###### How to call:
#        run_bench.sh output_dir tmp_dir min_cores max_cores
#
#     output_dir:  where this will place its output file, gemm-blis.csv
#     tmp_dir:  directory to use for temporary files.  This is not
#     min_cores:  minimum number of cores to use.  
#     max_cores:  maximum number of cores to use.
#     A value of -1 for both min_cores and max_cores means "run 2 iterations
#     with as few cores as allowed by the benchmark using a small test case."


OUTPUT_DIR=$1
WORK_DIR=$2
MIN_CORES=$3
MAX_CORES=$4 

# What directory is this script in?
BENCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Default to the real executable
BENCH_EXE=$BENCH_DIR/bin/stream.avx2


# Create a subdirectory for this in WORK_DIR
mkdir -p $WORK_DIR/stream-avx2

# Check for special testing mode.
#  For some benchmarks, the range might be 8,12,16,20,24,28,32
#     and the run_bench.sh needs to figure out appropriate things
#     with min_cores and max_cores.  
if (( $MIN_CORES == -1 && $MAX_CORES == -1 )); then  
  echo Running stream-avx2 in test mode.
  MIN_CORES=1
  MAX_CORES=2
  BENCH_EXE=$BENCH_DIR/bin/stream.test
fi
 
 
# just in case
unset OMP_NUM_THREADS

#  For the DGEMM benchmark it is straightforward to test all cores
#  in the specified range over a set of matrix sizes.  
#

# Run all of the benchmarks for all available processors.  Run out of the
# $WORK_DIR for all temp output.
cd $WORK_DIR/stream-avx2
rm -f stream-avx2.out
touch stream-avx2.out

# Set OpenMP variables
export OMP_PROC_BIND=close

i=1
for i in $(seq $MIN_CORES $MAX_CORES); do 
  export OMP_NUM_THREADS="$i"
  # Extract just a summary from the output with the # of threads, a header, and the Triad result.
  $BENCH_EXE | egrep "Number of Threads requested|Function|Triad|Failed|Expected|Observed" >> stream-avx2.out
done

 
python3 $BENCH_DIR/filter.py $WORK_DIR/stream-avx2/stream-avx2.out > $OUTPUT_DIR/stream_avx2.csv
 
 



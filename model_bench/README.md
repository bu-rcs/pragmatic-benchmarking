# model_bench

## Program:  sleep

    sleep is a bash program that sleeps for a time.  
    
    This is an example of how to set up a benchmark.  This can be used as 
    a template for other README.md files.  

## Configuration:
    
    info about config files etc. if there are any.

## Execution:
    
    `sleep <# of seconds to sleep>`
    
## Example:
 
    `sleep 4`
    
## Contributor:

    who gave us this, name & email.


---

## Benchmark Directory Structure:
    | Item | Description |
    | ----------- | ----------------------------------- |
    | src/ | Source code and a build.sh script (optional)
    | bin/ | all executable files                       |
    | data/ | data files, compressed as much as possible (optional)
    | lib/ | All required shared libaries to run the program (optional)
    | README.md | This file |
    | run_bench.sh | script to run benchmark | 
    | filter.py | Python script to create .csv output |
    | benchmark files | The executable(s), scripts etc. |
    
Notes:
* src/build.sh is a script to do whatever build steps are necessary, using whatever tools (make, cmake, etc) are needed.
* data, lib, and src directories are all optional.
* run_bench.sh is a required file, it will run the benchmark, takes the output, and hands it off to filter.py for CSV formatting.
* filter.py is used to filter & format the output or log file from the benchmark into the final CSV format. This is customized for each benchmark.
* run_bench.sh - this file is required and must have this name for execution by the top-level run_all_benchmarks.sh script.

## Setting up a Benchmark

In the src/ directory, do whatever is needed to build/compile the benchmark program using build.sh. The details depend on what you're doing - if you're running an R script and R is available on the system then there's no need to create a build.sh.  If you want to build a Singularity container, install R into it, and use that to run your R script then those steps would be performed in build.sh and the container copied to the bin directory.  build.sh should also copy any required libraries and data files to the lib/ and data/ directories.

Configure run_bench.sh to run the benchmark code, writing all output to a working directory. If the benchmark can use multiple cores, make sure to make use of the MIN_CORES and MAX_CORES input arguments appropriately. A value of (-1,-1) for the min/max cores indicates a very abbreviated test should be run, for example running a code with a toy dataset, in order to facilitate testing the benchmarking scripts.

Edit filter.py as needed to parse the benchmark's output into a CSV file. Our implementation used Python exclusively for this step for consistency, but you can use any means you want to create the CSV file by editing the run_bench.sh  

 





    

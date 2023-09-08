#!/bin/env python3
#

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

#   A Python 3 script that takes the timing output or
#   program log output from run_bench.sh and writes a
#   .csv file to stdout that is ready to use
#   in plotting software.
#

# python3 filter.py benchmark_output_file 

import sys

if __name__=='__main__':
    datafile = sys.argv[1]
    
    # print a header line
    print('NCORES,time')
    # do whatever is needed to process the datafile
    with open(datafile) as f:
        # typically the log file or other output from the benchmark
        # program states how many cores were used and that value
        # is parsed out. Here, just count.
        cores=1
        for i, line in enumerate(f):
            if line.find('elapsed') >= 0:
                val = line.split()[2]
                val = val.split('elapsed')[0]
                print(f'{cores},{val}')
                cores +=1 
        

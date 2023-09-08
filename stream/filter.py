#!/bin/env python3

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

import sys

# Run:

# python filter.py input_file > output_file


# filter the stream benchmark output. The run_bench.sh runs
# egrep which does some initial filtering.  The resulting
# file as read by this script looks like this:

#    Number of Threads requested = 1
#    Function    Best Rate MB/s  Avg time     Min time     Max time
#    Triad:      22019.7519       0.0022       0.0022       0.0022
#    Number of Threads requested = 2
#    Function    Best Rate MB/s  Avg time     Min time     Max time
#    Triad:      45241.9308       0.0011       0.0011       0.0011




# Print the output header
print("Ncores,MB/sec")

# Now loop through the lines.  Parse out the number of threads and the
# Triad result.
with open(sys.argv[1]) as f:
    nthr = None
    triad = None
    for line in f.readlines():
        tmp = line.split()
        if not nthr and line.find('Number') >= 0:
            # Found a Number line.
            nthr = int(tmp[5])
        if not triad and line.find('Triad') >= 0:
            triad = float(tmp[1])
        if nthr and triad:
            # Found both values. Print and re-set to None.
            print('%s,%s' % (nthr,triad))
            nthr = triad = None
            

        

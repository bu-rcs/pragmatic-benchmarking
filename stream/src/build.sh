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

# This is the latest STREAM benchmark.  It dynamically allocates
# its test arrays using memory alignment. 

# A proper Makefile could be used here, and then this 
# script would just run "make" and "make install".

 

CC=gcc
# Compile with AVX2 instructions
CFLAGS="-O3  -static -fopenmp -mavx2"
 
 
# Set the minimum stream array size.  Note from the source
# code:
#Example 2: Two Xeon E5's with 20 MB L3 cache each (using OpenMP)
# *               STREAM_ARRAY_SIZE should be >= 20 million, giving
# *               an array size of 153 MB and a total memory requirement
# *               of 458 MB.  
# Let's use an array size of 600 million for a very generous margin over
# the size of potential L3 caches.  A bigger size just makes it take longer
# to run but a size that's too small results in cache effects impacting results.

STREAM_ARRAY_SIZE="-DSTREAM_ARRAY_SIZE=600000000"

# Compile for AVX2. 
gcc $CFLAGS $STREAM_ARRAY_SIZE   -o stream.avx2 stream_5-10_posix_memalign.c
 
# Compile again but with a very small STREAM_ARRAY_SIZE which must be at
# least 2 million for STREAM to run right.  This is the test program. In this 
# program the array size is compiled into the program so using 2 separate
# binaries makes sense. Other programs would just use arguments or config
# files.
STREAM_ARRAY_SIZE_SM="-DSTREAM_ARRAY_SIZE=2000000"
gcc $CFLAGS $STREAM_ARRAY_SIZE_SM -o stream.test stream_5-10_posix_memalign.c


# and move 'em to the bin dir.
mv stream.avx2  stream.test  ../bin
 

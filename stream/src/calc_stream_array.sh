#!/bin/bash
 
# Script to produce a suggested array size for a system.  Check that
# the number in build.sh is at least this size.
 
# Originally this was the "stream-scaling" script 
# from Gregory Smith:  https://github.com/gregs1104/stream-scaling
# BSD license: 

# License
# 
# stream-scaling is licensed under a standard 3-clause BSD license.
# 
# Copyright (c) 2010-2015, Gregory Smith All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
# 
#         Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#         Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
#            in the documentation and/or other materials provided with the distribution.
#         Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this 
#            software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



# The default way stream is compiled, it operates on a array of
# 2,000,000 elements taking up approximately 46MB of RAM.  If the
# total amount of processor cache on your system exceeds this amount,
# that means more of the data will fit in cache than intended, and
# the results will be inflated.  Accordingly, this cache size is
# estimated (in a way that only works on Linux), and the size of
# the array used is increased to be 10X as large as that total.
# The STREAM source code itself suggests a 4X multiplier should
# be enough.
STREAM_MIN=10000000

# Limit the maximum array sized used so that the data structure fits
# into a memory block without overflow.  This makes for about 3GB
# of memory just for the main array, plus some other structures,
# and just fits on most 64-bit systems.  A lower limit may
# be needed on some sytems.
MAX_ARRAY_SIZE=130000000

#
# Look for sysctl on this system.  It's often not in non-root user's PATH.
#
#
# Look for sysctl on this system.  It's often not in non-root user's PATH.
#
if command sysctl -a >/dev/null 2>&1; then
  SYSCTL=`which sysctl`
elif [ -x "/sbin/sysctl" ]; then
  SYSCTL="/sbin/sysctl"
else
  echo WARNING:  Could not find sysctl.  CPU and cache size detection will not work properly.
fi
# TODO Make all references to sysctl use this value
# TODO Mac-specific code below should test uname, not rely on sysctl being somewhere

#
# Determine maximum cores to test
#
# TODO GNUP coreutils nproc might be useful for some non-Linux systems
if [ -n "$1" ] ; then
  MAX_CORES="$1"
elif [ -f "/proc/cpuinfo" ] ; then
  MAX_CORES=`grep -c processor /proc/cpuinfo`
elif [ -x "/usr/sbin/sysctl" ] ; then
  # This should work on Mac OS X, FreeBSD
  MAX_CORES=`$SYSCTL -n hw.ncpu`
fi  

if [ -z "$MAX_CORES" ] ; then
  # Might as well have a default bigger than most systems ship with
  # if all else fails
  MAX_CORES=8
fi

# Uncomment this to get verbose output of every stream run
# By default, the first one includes full details, while later
# ones only show the Triad output and a confirmation of
# core count
#VERBOSE=1

# Uncomment to show more debugging output
#DEBUG=1

function total_cache_size {
# Total up all of the non-instructional caches for every CPU
# on the system.
#
# Takes one input:  the name of the variable to save the computed
# total cache size to.  Used bash eval track to pass that back.
# Value returned is in bytes.
#
# Inside of /sys/devices/system/cpu/cpu0/cache/ are a series of
# files named index[0..n] that represent each of the layers of
# cache on this CPU.  Each is labeled with a level, size, and
# type, contained in files with those names.  Valid types include 
# "Instruction", "Data", and "Unified".  Typical levels are 1
# through 3.  And sizes vary, but are always listed in values
# ending with "K".

  local  __resultvar=$1
  local TOTAL_CACHE_KB=0
  for C in /sys/devices/system/cpu/cpu*
  do
    for I in $C/cache/index*
    do
      if [ ! -f $I/size ] ; then
        continue
        fi
      local LEVEL=`cat $I/level`
      local CACHE=`cat $I/size`
      local TYPE=`cat $I/type`
      echo CPU $C Level $LEVEL Cache: $CACHE \($TYPE\)
      if [ "$TYPE" = "Instruction" ] ; then
        # Don't count instruction caches, just data & unified
        continue
      fi
  
      # Check the last character of the string to make
      # sure it's "K"; if not, we don't know what
      # we're looking at here    
      local KB=`expr "$CACHE" : '.*\(.\)'`
      if [ "$KB" = "K" ] ; then
        # Parse just the digits here
        local K=${CACHE%K}
        ((TOTAL_CACHE_KB = TOTAL_CACHE_KB + K))
      else
        echo Error:  can\'t interpret format of CPU cache information in $I/size
        return
      fi
    done
  done
  ((TOTAL_CACHE = TOTAL_CACHE_KB * 1024))
  eval $__resultvar="'$TOTAL_CACHE'"
}

function simple_cache_size {
  # Original, simpler cache size computation.  Doesn't give accurate
  # results at all on processors with L3 caches.  Intel CPUs will
  # typically publish that size into /proc/cpuinfo, while some
  # AMD processors with large L3 caches will instead publish
  # their L2 cache size to there.  Ultimately this is a better approach
  # anyway, because it will sum all of the various cache levels,
  # rather than just using the one that get published to the CPU
  # summary value.
  #
  # Left here as example code, in case some future processors that
  # provide cache info in /proc/cpuinfo but not /sys/devices/system/cpu
  # turn up.
  local TOTAL_CACHE_KB=0
  for cache in `grep "cache size" /proc/cpuinfo | cut -d":" -f 2 | cut -d" " -f 2`
  do
    if [ -n "$cache" ] ; then
      ((TOTAL_CACHE_KB = TOTAL_CACHE_KB + cache))
    fi
  done
  # Convert this from its unit of kilobytes into regular bytes, because "MB"
  # figures from stream are 1M, not 2^20
  local TOTAL_CACHE
  ((TOTAL_CACHE = TOTAL_CACHE_KB * 1024))
  eval $__resultvar="'$TOTAL_CACHE'"
}

# Guess the cache size based on sysctl info, which will work on some
# Apple Mac hardware.  Returns it into the variable name passed.
# Currently this just looks at L3 cache size and assumes that is
# close enough, given the margin factor build into the rest of the
# program.  It really should consider the other caches too.
function total_mac_cache_size {
  local  __resultvar=$1
  TOTAL_CACHE=`sysctl -n hw.l3cachesize`

  if [ -z "$TOTAL_CACHE" ] ; then
      echo Error:  can\'t interpret CPU cache information from sysctl
      return
  fi

  eval $__resultvar="'$TOTAL_CACHE'"
}

# Not working yet prototype for FreeBSD cache detection
function total_freebsd_cache_size {
  dmidecode | grep -A 5 "L3-Cache" | grep "Installed" | head -n 1
  # TODO This returns a line like this, and it needs to be multiplied by # cores
  # Installed Size: 12288 kB
  return
}

#
# stream_array_elements determines how large the array stream
# runs against needs to be to avoid caching effects.
#
# Takes one input:  the name of the variable to save the needed
# array size to.
#
function stream_array_elements {
  # Bash normally doesn't let functions return values usefully.
  # This and below eval __resultvar let it set variables outside
  # of the function more cleanly than using globals here.
  local  __resultvar=$1
  local NEEDED_SIZE=$STREAM_MIN

  total_cache_size TOTAL_CACHE

  if [ "$TOTAL_CACHE" -eq 0 ] ; then
    total_mac_cache_size TOTAL_CACHE
  fi

  if [ -z "$TOTAL_CACHE" ] ; then
    echo Unable to guess cache size on this system.  Using default.
    NEEDED_SIZE=$STREAM_MIN
    eval $__resultvar="'$NEEDED_SIZE'"
    return
  fi
  
  echo Total CPU system cache:  $TOTAL_CACHE bytes

  # We know that every 1 million array entries in stream produces approximately
  # 22 million bytes (not megabytes!) of data.  Round that down to make more
  # entries required.  And then increase the estimated sum of cache sizes by
  # an order of magnitude to compute how large the array should be, to make
  # sure cache effects are minimized.

  local BYTES_PER_ARRAY_ENTRY=22
  ((NEEDED_SIZE = 10 * TOTAL_CACHE / BYTES_PER_ARRAY_ENTRY))

  echo Suggested minimum array elements needed:  $NEEDED_SIZE

  if [ $NEEDED_SIZE -lt $STREAM_MIN ] ; then
    NEEDED_SIZE=$STREAM_MIN
  fi

  # The array sizing code will overflow 32 bits on systems with many
  # processors having lots of cache.  The compiler error looks like this:
  #
  # $ gcc -O3 -DN=133823657 -fopenmp stream.c -o stream
  # /tmp/ccecdC49.o: In function `checkSTREAMresults':
  # stream.c:(.text+0x34): relocation truncated to fit: R_X86_64_32S against `.bss'
  # /tmp/ccecdC49.o: In function `main.omp_fn.6':
  # stream.c:(.text+0x2a6): relocation truncated to fit: R_X86_64_32S against `.bss'
  # stream.c:(.text+0x348): relocation truncated to fit: R_X86_64_32S against `.bss'
  # stream.c:(.text+0x388): relocation truncated to fit: R_X86_64_32S against `.bss'
  # /tmp/ccecdC49.o: In function `main.omp_fn.8':
  # stream.c:(.text+0x4ed): relocation truncated to fit: R_X86_64_32S against `.bss'
  # stream.c:(.text+0x514): relocation truncated to fit: R_X86_64_32S against `.bss'
  # stream.c:(.text+0x548): relocation truncated to fit: R_X86_64_32S against `.bss'
  # stream.c:(.text+0x58c): relocation truncated to fit: R_X86_64_32S against `.bss'
  # /tmp/ccecdC49.o: In function `main.omp_fn.9':
  # stream.c:(.text+0x615): relocation truncated to fit: R_X86_64_32S against `.bss'
  # stream.c:(.text+0x660): relocation truncated to fit: R_X86_64_32S against `.bss'
  # stream.c:(.text+0x6ab): additional relocation overflows omitted from the output
  # collect2: ld returned 1 exit status
  #  
  # Warn about this issue, and provide a way to clamp the upper value to a smaller
  # maximum size to try and avoid this error.  130,000,000 makes for approximately
  # a 3GB array.  The large memory model compiler option will avoid this issue
  # if a gcc version that supports it is available.
  if [ $NEEDED_SIZE -gt $MAX_ARRAY_SIZE ] ; then
    #
    # Size clamp code
    #
    # Uncomment this line if stream-scaling fails to work on your system with
    # "relocation truncated to fit" errors.  Note that results generated in
    # this case may not be reliable.  Be suspicious of them if the speed
    # results at the upper-end of the processor count seem extremely large
    # relative to similar systems.

    #NEEDED_SIZE=$MAX_ARRAY_SIZE

    echo WARNING:  Array size may not fit into a 32 bit structure.
    echo If stream files to compile, you may need to uncomment the
    echo line in the script labeled and described by the \"Size
    echo clamp code\" comments in the stream-scaling script.
  fi

  # Given the sizing above uses a factor of 10X cache size, this reduced size
  # might still be large enough for current generation procesors up to the 48 core
  # range.  For example, a system containing 8 Intel Xeon L7555 processors with
  # 4 cores having 24576 KB cache each will suggest:
  #
  # Total CPU system cache: 814743552 bytes
  # Computed minimum array elements needed: 370337978
  #
  # So using 130,000,000 instead of 370,337,978 still be an array >3X the
  # size of the cache sum in this case.  Really large systems with >48 processors
  # might overflow this still.

  echo Array elements used:  $NEEDED_SIZE
  eval $__resultvar="'$NEEDED_SIZE'"
  return
}

#
# Execute cache size estimations
#

echo === CPU cache information ===
stream_array_elements ARRAY_SIZE
ARRAY_FLAG="-D STREAM_ARRAY_SIZE=$ARRAY_SIZE"
echo Array size is $ARRAY_SIZE
echo Array flag is $ARRAY_FLAG

 

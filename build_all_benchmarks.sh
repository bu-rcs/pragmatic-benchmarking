#!/bin/bash


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

# This is for building binaries that are too big to include
# in the Github repo.

# build binaries:
#     ./build_all_benchmarks.sh
#
# build binaries and deploy to processor-benchmarks.tgz
#     ./build_all_benchmarks.sh /path/to/deploy/directory

BUILD_ALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# This is the list of benchmarks that need their build.sh to be run.
declare -a ALL_BENCHMARKS=(stream)

for BENCH_PROG in "${ALL_BENCHMARKS[@]}"
do
        cd $BUILD_ALL_DIR/$BENCH_PROG/src
        ./build.sh
done ;
    


# Option - pack up a tar file after bulding.

if [ $# -ge 1 ] ; then
    cd $BUILD_ALL_DIR
    DEPLOY_DIR=$1
    mkdir -p $DEPLOY_DIR/processor-benchmarks
    echo Copying files.
    cp -r * $DEPLOY_DIR/processor-benchmarks
    pushd $DEPLOY_DIR
    tar zcfv processor-benchmarks.tgz processor-benchmarks
    rm -rf processor-benchmarks
    popd
    echo Deployed to:  $DEPLOY_DIR/processor-benchmarks.tgz
fi

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
import shlex
import os
import shutil
import glob
import subprocess
import pprint

# This is a tool that will examine a directory of shared libraries and binaries,
# find all of their dependencies in a recursive sense, and copy all of them
# to a destination directory.


def list_executables(src_dir):
    ''' List all of the executable files in a directory 
        from: https://stackoverflow.com/questions/8957653/how-do-i-search-for-an-executable-file-using-python-in-linux
    '''
    exes = []
    for basename in os.listdir(src_dir):
        filename = os.path.join(src_dir,basename)
        if os.path.isfile(filename) and os.access(filename, os.X_OK):
            exes.append(filename)
    return exes

def ldd_get_dep_lib(filename, filter_string=None):
    ''' Runs ldd on a file and returns an optionally filtered
        set of all of the files that it depends on.'''
    cmd = shlex.split('ldd %s' % filename)
    ps = subprocess.Popen(cmd,stdout=subprocess.PIPE)
    ldd_output,err = ps.communicate() 
    dep_libs = []
    for ldd_line in ldd_output.decode('ascii').split('\n'):
        if filter_string:
            # if the filter string is not found skip this one
            if ldd_line.find(filter_string) < 0:
                continue
        spl = ldd_line.split()
        if len(spl) >= 3:
            if os.path.isfile(spl[2]):
                dep_libs.append(spl[2])
    # The set guarantees everything will be unique.
    return set(dep_libs)

def create_symlink(shared_lib):
    ''' Create a symlink to the shared lib.
        libfoo.6.1.2.so gets libfoo.so as a symlink.
    '''
    lib_name = os.path.basename(shared_lib)
    link_name = lib_name.split('.')[0] + '.so'
    # symlink only if the libname is NOT already libfoo.so
    if link_name != lib_name: 
        link_path = os.path.join(os.path.dirname(shared_lib),link_name)
        os.symlink(shared_lib,link_path)
        
def get_all_deps(lib_set,filter_string=None):
    ''' Take a set of shared libs.  Visit each recursively and 
        build up the complete set of dependent shared libs.'''
    def get_all_deps_recursive(lib_set,deps,filter_string):
        for name in deps:   
            new_deps = ldd_get_dep_lib(name, filter_string)
            if len(new_deps)==0:
                return lib_set
            lib_set.update(new_deps)
            get_all_deps_recursive(lib_set,new_deps,filter_string)
    initial_lib_set = lib_set.copy()
    return get_all_deps_recursive(lib_set,initial_lib_set,filter_string)

if __name__=='__main__':
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print('\n\nUsage:')
        print('\n   python build_unified_libs.py source_dir dest_dir optional_filter_string\n')
        print('The destination dir will be created if needed and replaced if it exists.')
        print('The optional filter string looks for dependent libraries with a particular substring, e.g. pkg.7\n\n')
        exit(0)
    src_dir = sys.argv[1]    
    dest_dir = sys.argv[2]
    filter_string = None
    if len(sys.argv)==4:
        filter_string = sys.argv[3]
        
    if not os.path.exists(src_dir):
        print('The source directory does not exist!')
        exit(1)
        
    # Delete if necessary then create the destination directory
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
    os.makedirs(dest_dir)
    
    # Get the shared libraries in the source directory
    shared_libs=glob.glob(os.path.join(src_dir,'*.so.*'))    
    # Get the executables in the source directory
    exes = list_executables(src_dir)

    # And join that to the shared libs to get everything in one go.
    all_shared = shared_libs + exes

    if len(all_shared)==0:
        print('There are no shared libraries or executables in the source directory: %s' % src_dir)
        exit(1)
        
    deps=set()
    for shar in all_shared:
        deps.update(ldd_get_dep_lib(shar,filter_string))

    # now take the set of shared libraries and recursively repeat...
    all_deps = get_all_deps(deps,filter_string)

    # And finally copy all of them to the destination directory
    if not all_deps:
        exit(0) # nothing to do, quit!
        
    pp = pprint.PrettyPrinter(indent=4)
    print('Libraries to be copied:')
    pp.pprint(all_deps)    
    for dep in all_deps:
        try:
            dest = os.path.join(dest_dir,os.path.basename(dep))
            shutil.copy(dep,dest)
            create_symlink(dest)
        except IOError as e:
            print('Unable to copy file. %s' % e)
        except:
            print('Unexpected error:', sys.exc_info())
    

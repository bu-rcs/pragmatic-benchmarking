This is a tool that will examine a directory of shared libraries and binaries, find all of their dependencies in a recursive sense, and copy all of them to a destination directory.

The application for benchmarking is for helping to build a self-contained benchmark program. Once a binary is built, `build_unified_libs.py` is used to copy all required shared libraries to the benchmark lib/ directory. 

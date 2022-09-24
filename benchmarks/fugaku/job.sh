#!/bin/bash
#PJM -L "node=16"                  # Number of node
#PJM -L "rscgrp=small-s1"          # Specify resource group
#PJM -L "elapse=1:00:00"           # Job run time limit value
#PJM --mpi "max-proc-per-node=32"  # Upper limit of number of MPI process created at 1 node
#PJM -S                            # Direction of statistic information file output

# Do not write empty stdout/stderr files for MPI processes.
export PLE_MPI_STD_EMPTYFILE=off

JULIA="/data/ra000019/a04463/nightly/julia-7eacf1b68a/bin/julia"

cd ../..
mpiexecjl --project=. "${JULIA}" --project --startup-file=no --color=yes \
          -L traffic-mpi.jl \
          -e 'main_mpi(; maxiter=40, verbose=false); for _ in 1:5; main_mpi(; ncell=5120000, maxiter=1000, weak=true); end'

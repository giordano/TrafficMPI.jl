#!/bin/bash
#PJM -L "node=16"                  # Number of node
#PJM -L "rscgrp=small-s1"          # Specify resource group
#PJM -L "elapse=1:00:00"           # Job run time limit value
#PJM --mpi "max-proc-per-node=48"  # Upper limit of number of MPI process created at 1 node
#PJM -S                            # Direction of statistic information file output

# Do not write empty stdout/stderr files for MPI processes.
export PLE_MPI_STD_EMPTYFILE=off

JULIA="/data/ra000019/a04463/nightly/julia-7eacf1b68a/bin/julia"

cd ../..
for i in {1..5}; do
    mpiexecjl --project=. "${JULIA}" --project --startup-file=no --color=yes \
              -L traffic-mpi.jl \
              -e 'main_mpi(; ncell=30720, maxiter=100, verbose=false); main_mpi(; ncell=5120000, maxiter=1000, weak=true)' || true
    mpiexecjl --project=. "${JULIA}" --project --startup-file=no --color=yes \
              -L traffic-mpi.jl \
              -e 'main_mpi(; ncell=30720, maxiter=100, verbose=false); main_mpi(; ncell=2560000, maxiter=2000, weak=true)' || true
done

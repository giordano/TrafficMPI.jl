using MPI

include(joinpath(@__DIR__, "traffic.jl"))

function updatebcs_mpi!(road, rankup, rankdown, comm)
    MPI.Sendrecv!(@view(road[end - 1]), rankup, 1,
                  @view(road[begin]), rankdown, 1,
                  comm)
    MPI.Sendrecv!(@view(road[begin + 1]), rankdown, 1,
                  @view(road[end]), rankup, 1,
                  comm)
    # # With MPI.jl v0.20 you can use instead
    # MPI.Sendrecv!(@view(road[end - 1]), @view(road[begin]), comm;
    #               source=rankdown, dest=rankup)
    # MPI.Sendrecv!(@view(road[begin + 1]), @view(road[end]), comm;
    #               source=rankup, dest=rankdown)
end

function updateroad_mpi!(newroad, oldroad, sbuf, rbuf, comm)
    sbuf[] = updateroad!(newroad, oldroad)
    MPI.Allreduce!(sbuf, rbuf, +, comm)
    return rbuf[]
end

function kernel!(newroad, oldroad, rankup, rankdown, sbuf, rbuf, comm)
    updatebcs_mpi!(oldroad, rankup, rankdown, comm)
    nmove = updateroad_mpi!(newroad, oldroad, sbuf, rbuf, comm)
    # Copy new to old array
    for idx in eachindex(oldroad, newroad)[(begin + 1):(end - 1)]
        @inbounds oldroad[idx] = newroad[idx]
    end
    return nmove
end

function main_mpi(; ncell::Int=10240000, maxiter::Int=1000, weak::Bool=false, verbose::Bool=true)
    MPI.Init()

    comm = MPI.COMM_WORLD

    size = MPI.Comm_size(comm)
    rank = MPI.Comm_rank(comm)

    # If doing weak scaling, increase number of cells by size of MPI processes
    if weak
        ncell *= size
    end

    # Simulation parameters
    seedval = 5743
    rng = Random.seed!(seedval)
    printfreq = div(maxiter, 10)

    nlocal = div(ncell, size)

    # Check consistency

    if nlocal * size != ncell
        if iszero(rank)
            println("ERROR: ncell = $(ncell) not a multiple of size = $(size)")
        end
        exit(1)
    end

    # Create full `bigroad` vector only on rank 0, otherwise make it empty as
    # it's unused.  Also, it'll be initialised later, don't waste time setting
    # it to zeros.
    bigroad  = Vector{Int32}(undef, iszero(rank) ? ncell : 0)
    newroad  = zeros(Int32, nlocal + 2)
    oldroad  = zeros(Int32, nlocal + 2)

    sbuf = Ref{Int32}(0)
    rbuf = Ref{Int32}(0)

    density = 0.52

    if iszero(rank)
        if verbose
            println("Length of road is $(ncell)")
            println("Number of iterations is $(maxiter)")
            println("Target density of cars is $(density)")
            println("Running on $(size) process(es)")

            # Initialise road accordingly using random number generator
            println("Initialising ...")
        end

        initroad!(bigroad, density, rng)
        ncars = count(isone, bigroad)

        if verbose
            println("Actual Density of cars is $(ncars / ncell)")
            println()
            println("Scattering data ...")
        end
    end

    MPI.Scatter!(bigroad, @view(oldroad[(begin + 1):(end - 1)]), 0, comm)
    # # Wtih MPI.jl v0.20 you can use instead
    # MPI.Scatter!(bigroad, @view(oldroad[(begin + 1):(end - 1)]), comm; root=0)

    if verbose && iszero(rank)
        println("... done")
        println()
    end

    # Compute neighbours

    rankup   = (rank + 1) % size
    rankdown = (rank + size - 1) % size

    nmove = 0
    nmovelocal = 0

    MPI.Barrier(comm)
    tstart = MPI.Wtime()

    for iter in 1:maxiter
        nmove = kernel!(newroad, oldroad, rankup, rankdown, sbuf, rbuf, comm)

        if verbose && iszero(iter % printfreq) && iszero(rank)
            println("At iteration $(iter) average velocity is $(nmove / ncars)")
        end
    end

    MPI.Barrier(comm)
    tstop = MPI.Wtime()

    if verbose && iszero(rank)
        println()
        println("Finished")
        println()
        println("Time taken was $(tstop - tstart) seconds")
        println("Update rate was $(1.0e-6 * ncell * maxiter / (tstop-tstart)) MCOPs")
    end
end

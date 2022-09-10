using MPI

include(joinpath(@__DIR__, "traffic.jl"))

function kernel!(newroad, oldroad, sbuf, rbuf, nlocal, rankup, rankdown, comm)
    MPI.Sendrecv!(@view(oldroad[nlocal:nlocal]), rankup, 0,
                  @view(oldroad[1:1]), rankdown, 0,
                  comm)
    MPI.Sendrecv!(@view(oldroad[2:2]), rankdown, 0,
                  @view(oldroad[(nlocal+2):(nlocal + 2)]), rankup, 0,
                  comm)
    # # With MPI.jl v0.20 you can use instead
    # MPI.Sendrecv!(@view(oldroad[nlocal]), @view(oldroad[1]), comm;
    #               source=rankdown, dest=rankup)
    # MPI.Sendrecv!(@view(oldroad[2]), @view(oldroad[(nlocal+2)]), comm;
    #               source=rankup, dest=rankdown)


    sbuf[begin] = updateroad!(newroad, oldroad)
    MPI.Allreduce!(sbuf, rbuf, +, comm)
    nmove = rbuf[begin]

    # Copy new to old array
    # @views oldroad[2:(end - 1)] .= newroad[2:(end - 1)]
    for idx in 2:(nlocal + 1)
        @inbounds oldroad[idx] = newroad[idx]
    end

    return nmove
end

function main_mpi(; ncell::Int=10240000, maxiter::Int=1000)
    MPI.Init()

    comm = MPI.COMM_WORLD

    size = MPI.Comm_size(comm)
    rank = MPI.Comm_rank(comm)

    # Simulation parameters
    seedval = 5743
    rng = Random.seed!(seedval)
    printfreq = maxiter ÷ 10

    nlocal = ncell ÷ size

    # Check consistency

    if nlocal * size != ncell
        if iszero(rank)
            println("ERROR: ncell = $(ncell) not a multiple of size = $(size)")
        end
        exit(1)
    end

    bigroad  = zeros(Int32, ncell)
    newroad  = zeros(Int32, nlocal + 2)
    oldroad  = zeros(Int32, nlocal + 2)

    sbuf = zeros(Int32, 1)
    rbuf = zeros(Int32, 1)

    density = 0.52

    if iszero(rank)
        println("Length of road is $(ncell)")
        println("Number of iterations is $(maxiter)")
        println("Target density of cars is $(density)")
        println("Running on $(size) process(es)")

        # Initialise road accordingly using random number generator
        println("Initialising ...")

        initroad!(bigroad, density, rng)
        ncars = count(isone, bigroad)

        println("Actual Density of cars is $(ncars / ncell)")
        println()
        println("Scattering data ...")

    end

    MPI.Scatter!(bigroad, @view(oldroad[2:nlocal]), 0, comm)
    # # Wtih MPI.jl v0.20 you can use instead
    # MPI.Scatter!(bigroad, @view(oldroad[2:nlocal]), comm; root=0)

    if iszero(rank)
        println("... done")
        println()
    end

    # Compute neighbours

    rankup   = rank + 1
    rankdown = rank - 1

    # Wrap-around for cyclic boundary conditions, i.e. a roundabout

    if rankup == size
        rankup = 0
    end

    if rankdown == -1
        rankdown = size - 1
    end

    nmove = 0
    nmovelocal = 0

    MPI.Barrier(comm)
    tstart = MPI.Wtime()

    for iter in 1:maxiter
        nmove = kernel!(newroad, oldroad, sbuf, rbuf, nlocal, rankup, rankdown, comm)

        if iszero(iter % printfreq)
            if iszero(rank)
                println("At iteration $(iter) average velocity is $(nmove / ncars)")
            end
        end
    end

    MPI.Barrier(comm)
    tstop = MPI.Wtime()

    if iszero(rank)
        println()
        println("Finished")
        println()
        println("Time taken was $(tstop - tstart) seconds")
        println("Update rate was $(1.0e-6 * ncell * maxiter / (tstop-tstart)) MCOPs")
    end
end

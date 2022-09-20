using Random

initroad!(road, density, rng=Random.default_rng()) = 
    road .= Int32.(rand.(rng, Float32) .< density)

function updateroad!(newroad, oldroad)
    nmove = Int32(0)
    for i in eachindex(oldroad, newroad)[(begin + 1):(end - 1)]

        if isone(oldroad[i])
            if isone(oldroad[i + 1])
                @inbounds newroad[i] = Int32(1)
            else
                @inbounds newroad[i] = Int32(0)
                nmove += Int32(1)
            end
        else
            @inbounds newroad[i] = Int32(isone(oldroad[i - 1]))
        end

        # newroad[i] = ifelse(iszero(oldroad[i]), oldroad[i-1], oldroad[i+1])
        # nmove = nmove + Int(newroad[i] != oldroad[i])

    end
    return nmove
end

function updatebcs!(road)
    road[begin] = road[end - 1]
    road[end]   = road[begin + 1]
end

function kernel!(newroad, oldroad)
    updatebcs!(oldroad)
    nmove = updateroad!(newroad, oldroad)
    # Copy new to old array
    for idx in eachindex(oldroad, newroad)[(begin + 1):(end - 1)]
        @inbounds oldroad[idx] = newroad[idx]
    end
    return nmove
end

function main(; ncell::Int=10240000, maxiter::Int=100)
    seedval = 5743
    rng = Random.seed!(seedval)
    printfreq = maxiter ÷ 10

    tmproad = zeros(Int32, ncell)
    newroad = zeros(Int32, ncell + 2)
    oldroad = zeros(Int32, ncell + 2)

    density = 0.52

    println("Length of road is $(ncell)")
    println("Number of iterations is $(maxiter)")
    println("Target density of cars is $(density)")

    # Initialise road accordingly using random number generator
    println("Initialising ...")
    initroad!(tmproad, density, rng)
    ncars = count(isone, tmproad)
    println("Actual Density of cars is $(ncars/ncell)")
    println()
    oldroad[2:(end - 1)] = tmproad
    tstart = time()
    @inbounds for iter in 1:maxiter
        nmove = kernel!(newroad, oldroad)
        if iszero(iter % printfreq)
            println("At iteration $(iter) average velocity is $(nmove/ncars)")
        end
    end
    tstop = time()

    println()
    println("Finished")
    println()
    println("Time taken was $(tstop-tstart) seconds")
    println("Update rate was $(1.0e-6 * ncell * maxiter / (tstop-tstart)) MCOPs")

    return nothing
end

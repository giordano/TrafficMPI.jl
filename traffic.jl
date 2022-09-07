using Random

initroad!(road, density, rng=Random.default_rng()) = 
    road .= Int.(rand.(rng) .< density)

function updateroad!(newroad, oldroad)
    n = length(oldroad) - 2
    nmove = 0
    for i in 2:n

        if oldroad[i] == 1
            if oldroad[i + 1] == 1
                newroad[i] = 1
            else
                newroad[i] = 0
                nmove += 1
            end
        else
            newroad[i] = ifelse(isone(oldroad[i - 1]), 1, 0)
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

function main()
    seedval = 5743
    rng = Random.seed!(seedval)
    ncell = 10240000
    maxiter = 1024000000 ÷ ncell
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
    oldroad[2:(end - 1)] = tmproad
    tstart = time()
    @inbounds for iter in 1:maxiter
        updatebcs!(oldroad)
        nmove = updateroad!(newroad, oldroad)
        # Copy new to old array
        for i in 2:ncell
            oldroad[i] = newroad[i]
        end
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

end

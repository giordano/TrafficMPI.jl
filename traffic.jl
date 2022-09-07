using Random

function initroad(road, density, rng=Random.default_rng())
    ncar = 0
    n = length(road)
    for i in 1:n
        if rand(rng) < density
            road[i] = 1
        else
            road[i] = 0
        end
        ncar += road[i]
    end
    return ncar
end

function updateroad(newroad, oldroad)
    n = length(oldroad) - 2
    nmove = 0
    for i in 1:n
        if oldroad[i] == 1
            if oldroad[i + 1] == 1
                newroad[i] = 1
            else
                newroad[i] = 0
                nmove += 1
            end
        else
            newroad[i] = ifelse(oldroad[i - 1] == 1, 1, 0)
        end
    end
    return nmove
end

function updatebcs!(road)
    n = length(road) - 2
    road[1]     = road[n]
    road[n + 1] = road[1]
end

function main()
    seedval = 5743
    rng = Random.seed!(seedval)
    ncell = 10240000
    maxiter = 1024000000 ÷ ncell
    printfreq = maxiter ÷ 10

    tmproad = zeros(Int, ncell - 1)
    newroad = zeros(Int, ncell + 1)
    oldroad = zeros(Int, ncell + 1)

    density = 0.52

    println("Length of road is $(ncell)")
    println("Number of iterations is $(maxiter)")
    println("Target density of cars is $(density)")

    # Initialise road accordingly using random number generator
    println("Initialising ...")
    ncars = initroad(tmproad, density, rng)
    println("Actual Density of cars is $(ncars/ncell)")
    @views oldroad[2:ncell] = tmproad
    tstart = time()
    @inbounds for iter in 1:maxiter
        updatebcs!(oldroad)
        nmove = updateroad(newroad, oldroad)
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

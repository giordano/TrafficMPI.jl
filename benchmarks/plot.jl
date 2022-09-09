using CSV, DataFrames, Plots

# Yes, a DataFrame would be easier to deal with
function filter_data!(df::DataFrame, filter)
    filter!(filter, df)
    return df
end

plot_scaling!(p, df, label, linecolor) =
    plot!(p,
          df.var"number of ranks",
          df.var"performance (MCops)" ./ df.var"performance (MCops)"[begin] ./ df.var"number of ranks" .* df.var"number of ranks"[1];
          label,
          linewidth=2,
          linecolor,
          )

function plot_performance!(p, df, label, linecolor1, linecolor2)
    plot!(p,
          df.var"number of ranks",
          df.var"performance (MCops)";
          label,
          linewidth=2,
          linecolor=linecolor1,
          )
    plot!(p,
          df.var"number of ranks",
          df.var"performance (MCops)"[begin] .* df.var"number of ranks" ./ df.var"number of ranks"[begin];
          label=label * " ideal",
          linecolor=linecolor2,
          linewidth=1.5,
          linestyle=:dash,
          )
    return p
end

function _plot(system::String, scaling::Bool; filter=Returns(true), legend=:topleft)
    julia = CSV.read(joinpath(@__DIR__, lowercase(system), "julia.csv"), DataFrame)
    filter_data!(julia, filter)
    c = CSV.read(joinpath(@__DIR__, lowercase(system), "c.csv"), DataFrame)
    filter_data!(c, filter)
    python_path = joinpath(@__DIR__, lowercase(system), "python.csv")
    if isfile(python_path)
        python = CSV.read(joinpath(@__DIR__, lowercase(system), "python.csv"), DataFrame)
        filter_data!(python, filter)
    end
    fortran_path = joinpath(@__DIR__, lowercase(system), "fortran.csv")
    if isfile(fortran_path)
        fortran = CSV.read(joinpath(@__DIR__, lowercase(system), "fortran.csv"), DataFrame)
        filter_data!(fortran, filter)
    end
    ticks = julia.var"number of ranks"

    p = plot(;
             xticks=(ticks, ticks),
             xscale=:log10,
             xlabel="Number of ranks",
             ylabel=scaling ? "Scaling efficiency" : "Performance (MCops)",
             legend,
             title="Strong scaling of roundabout simulation on $(system)",
             )
    if scaling
        plot_scaling!(p, julia, "Julia", "blue")
        plot_scaling!(p, c, "C", "red")
        if isfile(python_path)
            plot_scaling!(p, python, "Python", "green")
        end
        if isfile(fortran_path)
            plot_scaling!(p, fortran, "Fortran", "purple")
        end
    else
        plot!(p; yscale=:log10)
        plot_performance!(p, julia, "Julia", "blue", "darkblue")
        plot_performance!(p, c, "C", "red", "darkred")
        if isfile(python_path)
            plot_performance!(p, python, "Python", "green", "darkgreen")
        end
        if isfile(fortran_path)
            plot_performance!(p, fortran, "Fortran", "purple", "purple")
        end
    end
end

function performance(system::String; kwargs...)
    _plot(system, false; kwargs...)
end

function scaling(system::String; kwargs...)
    _plot(system, true; kwargs...)
end

#=
Examples of usage:

performance("ARCHER2")
scaling("Fugaku"; filter=r -> r.var"number of roads" == 30720000 && r.var"number of ranks" ≥ 4, legend=:bottomleft)
=#

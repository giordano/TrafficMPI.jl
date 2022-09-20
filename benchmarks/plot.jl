using CSV, DataFrames, Plots

# Yes, a DataFrame would be easier to deal with
function filter_data!(df::DataFrame, filter)
    filter!(filter, df)
    return df
end

plot_scaling!(p, df, label, linecolor) =
    plot!(p,
          df.var"number of ranks",
          df.var"performance (MCOPs)" ./ df.var"performance (MCOPs)"[begin] ./ df.var"number of ranks" .* df.var"number of ranks"[1];
          label,
          linewidth=2,
          linecolor,
          )

plot_weak_scaling!(p, df, label) =
    plot!(p,
          df.var"number of nodes",
          df.var"time (seconds)"[1] ./ df.var"time (seconds)";
          label,
          linewidth=2,
          marker=:auto,
          )

function plot_performance!(p, df, label, linecolor1, linecolor2)
    plot!(p,
          df.var"number of ranks",
          df.var"performance (MCOPs)";
          label,
          linewidth=2,
          linecolor=linecolor1,
          )
    plot!(p,
          df.var"number of ranks",
          df.var"performance (MCOPs)"[begin] .* df.var"number of ranks" ./ df.var"number of ranks"[begin];
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
        python = CSV.read(python_path, DataFrame)
        filter_data!(python, filter)
    end
    fortran_path = joinpath(@__DIR__, lowercase(system), "fortran.csv")
    if isfile(fortran_path)
        fortran = CSV.read(fortran_path, DataFrame)
        filter_data!(fortran, filter)
    end
    ticks = julia.var"number of ranks"

    p = plot(;
             xticks=(ticks, ticks),
             xscale=:log10,
             xlabel="Number of ranks",
             ylabel=scaling ? "Scaling efficiency" : "Performance (MCOPs)",
             legend,
             title="Strong scaling of traffic simulation on $(system)",
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

function weak_scaling(system::String; filter=Returns(true), legend=:bottomleft)
    julia = CSV.read(joinpath(@__DIR__, lowercase(system), "julia-weak.csv"), DataFrame; comment="#")
    filter_data!(julia, filter)
    c_path = joinpath(@__DIR__, lowercase(system), "c-weak.csv")
    if isfile(c_path)
        c = CSV.read(c_path, DataFrame)
        filter_data!(c, filter)
    end
    c_gcc_path = joinpath(@__DIR__, lowercase(system), "c-gcc-weak.csv")
    if isfile(c_gcc_path)
        c_gcc = CSV.read(c_gcc_path, DataFrame)
        filter_data!(c_gcc, filter)
    end
    c_fujitsu_path = joinpath(@__DIR__, lowercase(system), "c-fujitsu-weak.csv")
    if isfile(c_fujitsu_path)
        c_fujitsu = CSV.read(c_fujitsu_path, DataFrame)
        filter_data!(c_fujitsu, filter)
    end
    python_path = joinpath(@__DIR__, lowercase(system), "python-weak.csv")
    if isfile(python_path)
        python = CSV.read(python_path, DataFrame)
        filter_data!(python, filter)
    end
    fortran_path = joinpath(@__DIR__, lowercase(system), "fortran-weak.csv")
    if isfile(fortran_path)
        fortran = CSV.read(fortran_path, DataFrame)
        filter_data!(fortran, filter)
    end
    fortran_gcc_path = joinpath(@__DIR__, lowercase(system), "fortran-weak-gcc.csv")
    if isfile(fortran_gcc_path)
        fortran_gcc = CSV.read(fortran_gcc_path, DataFrame)
        filter_data!(fortran_gcc, filter)
    end
    fortran_fujitsu_path = joinpath(@__DIR__, lowercase(system), "fortran-weak-fujitsu.csv")
    if isfile(fortran_fujitsu_path)
        fortran_fujitsu = CSV.read(fortran_fujitsu_path, DataFrame)
        filter_data!(fortran_fujitsu, filter)
    end
    ticks = julia.var"number of nodes"

    yticks = (2, 5, 10, 20, 50, 100)
    p = plot(;
             xticks=(ticks, ticks),
             xscale=:log10,
             # yticks=(yticks, yticks),
             # yscale=:log10,
             # ylims=(0, Inf),
             xlabel="Number of nodes",
             ylabel="Scaling efficiency",
             legend,
             title="Weak scaling of traffic simulation on $(system)",
             )
    plot_weak_scaling!(p, julia, "Julia")
    if isfile(c_path)
        plot_weak_scaling!(p, c, "C")
    end
    if isfile(c_gcc_path)
        plot_weak_scaling!(p, c_gcc, "C (GCC)")
    end
    if isfile(c_fujitsu_path)
        plot_weak_scaling!(p, c_fujitsu, "C (Fujitsu)")
    end
    if isfile(python_path)
        plot_weak_scaling!(p, python, "Python")
    end
    if isfile(fortran_path)
        plot_weak_scaling!(p, fortran, "Fortran")
    end
    if isfile(fortran_gcc_path)
        plot_weak_scaling!(p, fortran_gcc, "Fortran (GCC)")
    end
    if isfile(fortran_fujitsu_path)
        plot_weak_scaling!(p, fortran_fujitsu, "Fortran (Fujitsu)")
    end
    return p
end

#=
Examples of usage:

performance("ARCHER2")
scaling("Fugaku"; filter=r -> r.var"number of roads" == 30720000 && r.var"number of ranks" ≥ 4, legend=:bottomleft)
=#

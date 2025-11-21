using DelimitedFiles
using LinearAlgebra
using Printf
using Statistics

include("loadSPP.jl")
include("heuristicSPP.jl")
include("improvements.jl")


dat_dir = "../dat"
files = filter(f -> endswith(f, ".dat"), readdir(dat_dir))

alpha = 0.8
iter = 5

aco_results = []

for fname in files
    fullpath = joinpath(dat_dir, fname)
    println("Processing ACO: $fname")

    C, A = loadSPP(fullpath)

    t_start = time()
    x_best, value_best, tau_final, _, _ = ACO_SPP(C, A;
                                            num_ants=30,
                                            num_iter=60,
                                            alpha=1.0,
                                            beta=2.0,
                                            rho=0.1,
                                            Q=1.0,
                                            localSearch=false)
    elapsed = time() - t_start

    push!(aco_results, (fname, value_best, elapsed))
end


latex_aco = "aco_results.tex"

open(latex_aco, "w") do io
    println(io, "\\begin{longtable}{|c|c|c|}")
    println(io, "\\hline")
    println(io, "Fichier & Valeur ACO & Temps (s) \\\\")
    println(io, "\\hline")

    for (fname, val, t) in aco_results
        println(io, @sprintf("%s & %.1f & %.2f \\\\", fname, val, t))
    end

    println(io, "\\hline")
    println(io, "\\end{longtable}")
end

println("Tableau LaTeX ACO généré : aco_results.tex")
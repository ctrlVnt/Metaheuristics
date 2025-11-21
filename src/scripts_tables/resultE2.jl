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

results = []

#=
for fname in files
    fullpath = joinpath(dat_dir, fname)
    println("Processing: $fname")

    C, A = loadSPP(fullpath)

    t_start = time()
    x, value = heuristicGRASPnoImp(C, A, alpha, iter)
    elapsed = time() - t_start

    push!(results, (fname, value, elapsed))
end
=#

for fname in files
    fullpath = joinpath(dat_dir, fname)
    println("Processing: $fname")

    C, A = loadSPP(fullpath)

    t_start = time()
    x, value, zmin, zmoy, zmax, = heuristicGRASP(C, A, alpha, iter)
    elapsed = time() - t_start

    push!(results, (fname, value, zmin, zmoy, zmax, elapsed))
end


latex_file = "grasp_results_ei2PR.tex"

open(latex_file, "w") do io
    println(io, "\\begin{longtable}{|c|c|c|c|c|}")
    println(io, "\\hline")
    println(io, "Fichier & zmin & zmoy & zmax & Temps (s) \\\\")
    println(io, "\\hline")

    for (fname, value, zmin_vec, zmoy_vec, zmax_vec, t) in results
        # Calcola un unico valore per colonna
        zmin_val = minimum(zmin_vec)
        zmoy_val = mean(zmoy_vec)
        zmax_val = maximum(zmax_vec)

        println(io, @sprintf("%s & %d & %.1f & %d & %.2f \\\\", fname, zmin_val, zmoy_val, zmax_val, t))
    end

    println(io, "\\hline")
    println(io, "\\end{longtable}")
end

println("Tableau LaTeX généré : grasp_results_ei2PR.tex")

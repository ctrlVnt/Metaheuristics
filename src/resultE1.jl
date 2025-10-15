using DelimitedFiles
using LinearAlgebra
using Printf

include("loadSPP.jl")
include("heuristicSPP.jl")
include("improvements.jl")

# Directory contenente i file da testare
dat_dir = "../dat"

# Prendi tutti i file .dat in res_dir
files = readdir(dat_dir)
dat_files = filter(f -> endswith(f, ".dat"), files)

# Inizializza un array per memorizzare i risultati
results = []

# Loop sui file
for fname in dat_files
    fullpath = joinpath(dat_dir, fname)
    println("Processing file: $fname")

    # Carica il problema
    C, A = loadSPP(fullpath)

    # Heuristic
    t1 = time()
    x_heur = heuristicSPP(C, A)
    val_heur = sum(C .* x_heur)
    elapsed_heur = time() - t1

    # Local search 1–1
    t2 = time()
    x_best, val_best = localSearch_1_1(C, A, x_heur)
    elapsed_local = time() - t2

    # Salva i dati
    push!(results, (fname, val_heur, elapsed_heur, val_best, elapsed_local))
end

# Genera il file LaTeX
latex_file = "results_table.tex"
open(latex_file, "w") do io
    println(io, "Result E1")
    println(io, "\\begin{tabular}{lrrrr}")
    println(io, "\\hline")
    println(io, "File & Heuristic & Time (s) & Local Search & Time (s) \\\\")
    println(io, "\\hline")
    for (fname, val_heur, t_heur, val_local, t_local) in results
        println(io, @sprintf("%s & %.2f & %.2f & %.2f & %.2f \\\\", fname, val_heur, t_heur, val_local, t_local))
    end
    println(io, "\\hline")
    println(io, "\\end{tabular}")
end

println("Results saved in $latex_file")
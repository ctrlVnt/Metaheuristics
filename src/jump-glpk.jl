using DelimitedFiles
using LinearAlgebra
using Printf
using JuMP
using GLPK

include("loadSPP.jl")
include("setSPP.jl")

# Directory contenente i file da testare
dat_dir = "../dat2"

# Prendi tutti i file .dat
files = readdir(dat_dir)
dat_files = filter(f -> endswith(f, ".dat"), files)

# Inizializza un array per memorizzare i risultati
results = []

# Loop sui file
for fname in dat_files
    fullpath = joinpath(dat_dir, fname)
    println("Processing file: $fname")

    # Carica dati
    C, A = loadSPP(fullpath)

    # -------------------------------
    # GLPK (JuMP)
    # -------------------------------
    solverSelected = GLPK.Optimizer
    spp = setSPP(C, A)

    set_optimizer(spp, solverSelected)
     t_start = time()
    optimize!(spp)
    time_jump = time() - t_start

    # Salva i risultati
    push!(results, (fname, objective_value(spp), time_jump))
end

# ==============================================
# GENERAZIONE TABELLA LATEX
# ==============================================
latex_file = "results_jump.tex"
open(latex_file, "w") do io
    println(io, "Result E1")
    println(io, "\\begin{longtable}[c]{| c | c | c |}")
    println(io, "\\hline")
    println(io, "File & GLPK (JuMP) & Time (s) \\\\")
    println(io, "\\hline")
    for (fname, v_glpk, t_glpk) in results
        println(io, @sprintf("%s & %.0f & %.6f \\\\",
                             fname, v_glpk, t_glpk))
    end
    println(io, "\\hline")
    println(io, "\\end{longtable}")
end
# =========================================================================== #
# Compliant julia 1.x

# Using the following packages
using JuMP, GLPK
using LinearAlgebra

include("loadSPP.jl")
include("setSPP.jl")
include("getfname.jl")
include("heuristicSPP.jl")
include("improvements.jl")

# =========================================================================== #

# Loading a SPP instance
println("\nLoading...")
fname = "../dat/pb_100rnd0100.dat"
C, A = loadSPP(fname)
#@show C #profits
#@show A #constrants

# Solving a SPP instance with artigian method
println("\nSolving with heuristic...")
x_heur = heuristicSPP(C, A)
println("Heuristic solution value = ", sum(C .* x_heur))
#println("x = ", x_heur)

# Improvement with local search 1–1 exchange
#x_best, val_best = localSearch_1_1(C, A, x_heur)
#println("Local search = ", val_best)
x_best, val_best = deepestDescent_2_1(C, A, x_heur)
println("Deepest search = ", val_best)
#println("Local search = ", val_best, "  x = ", x_best)


# --------------- #

# Solving a SPP instance with GLPK
#println("\nSolving with GLPK...")
#solverSelected = GLPK.Optimizer
#spp = setSPP(C, A)

#set_optimizer(spp, solverSelected)
#optimize!(spp)

# Displaying the results
#println("z = ", objective_value(spp))
#print("x = "); println(value.(spp[:x]))

# =========================================================================== #

# Collecting the names of instances to solve
println("\nCollecting...")
target = "../dat"
fnames = getfname(target)

println("\nThat's all folks !")
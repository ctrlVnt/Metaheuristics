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

t1 = time();
# Loading a SPP instance
println("\nLoading...")
fname = "../dat/pb_200rnd0100.dat"
C, A = loadSPP(fname)
#@show C #profits
#@show A #constrants

# Solving a SPP instance with artigian method
println("\nSolving with heuristic...")
x_heur = heuristicSPP(C, A)
println("Heuristic solution value = ", sum(C .* x_heur))
#println("x = ", x_heur)
elapsed_time = time() - t1;
println("Heuristic search time = ", elapsed_time)

t2 = time();
# Improvement with local search 1–1 exchange
x_best, val_best = localSearch_1_1(C, A, x_heur)
println("Local search = ", val_best)

#revoir cet algorithme
#x_best, val_best = deepestDescent_1_1(C, A, x_heur)
#println("Deepest search = ", val_best)
#println("Local search = ", val_best, "  x = ", x_best)

end_time = time() - t2;
println("Time search time = ", end_time);

# In Grasp we insert alpha end iter
t3 = time();
alpha = 0.3
iter = 5
println("\nSolving with GRASP...")
x_heur, value = heuristicGRASP(C, A, alpha, iter)
println("Heuristic solution value = ", value)
end_grasp = time() - t3;
println("GRASP time = ", end_grasp);

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
#println("\nCollecting...")
#target = "../dat"
#fnames = getfname(target)

#println("\nThat's all folks !")
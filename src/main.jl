# =========================================================================== #
# Compliant julia 1.x

# Using the following packages
using JuMP, GLPK
using LinearAlgebra
using Statistics

include("loadSPP.jl")
include("setSPP.jl")
include("getfname.jl")
include("heuristicSPP.jl")
include("improvements.jl")
include("experiment.jl")

# =========================================================================== #

# Loading a SPP instance
println("\nLoading...")
fname = "../dat/pb_1000rnd0800.dat"
C, A = loadSPP(fname)
#@show C #profits
#@show A #constrants

# Solving a SPP instance with artigian method
t1 = time();
println("\nSolving with heuristic...")
x_heur = heuristicSPP(C, A)
println("Heuristic solution value = ", sum(C .* x_heur))
elapsed_time = time() - t1;
println("Heuristic search time = ", elapsed_time)


# Improvement with local search 1–1 exchange
t2 = time();
x_best, val_best = localSearch_1_1(C, A, x_heur)
println("Local search = ", val_best)
end_time = time() - t2;
println("Local search time = ", end_time);

t22 = time();
x_best, val_best = deepestDescent_1_1(C, A, x_heur)
println("Deepest search = ", val_best)

end_time22 = time() - t22;
println("Deepest search time = ", end_time22);


# In Grasp we insert alpha end iter
alpha = 0.8 # 1 casual 0 determinist
iter = 5


println("\nSolving with GRASP...")
t3 = time();
_, value, _, _, _ = heuristicGRASPnoImp(C, A, alpha, iter)
end_grasp = time() - t3;
println("Heuristic solution value = ", value)
println("GRASP time = ", end_grasp);


println("\nSolving with GRASP + path linking...")
t4 = time();
_, value, _, _, _ = heuristicGRASP(C, A, alpha, iter)
end_grasp2 = time() - t4;
println("Heuristic solution value = ", value)
println("GRASP + Path Relinking time = ", end_grasp2);


println("\nSolving with ACO...")
t5 = time()
_, val_aco, tau, _, _, _ = ACO_SPP(C, A;
                               num_ants=30,
                               num_iter=60,
                               alpha=1.0,
                               beta=2.0,
                               rho=0.1,
                               Q=1.0,
                               localSearch=false)
end_aco = time() - t5
println("ACO solution value = ", val_aco)
println("ACO time = ", end_aco)

# --------------- #
#=
# Solving a SPP instance with GLPK
println("\nSolving with GLPK...")
solverSelected = GLPK.Optimizer
spp = setSPP(C, A)

#set_optimizer(spp, solverSelected)
optimize!(spp)

# Displaying the results
println("z = ", objective_value(spp))
print("x = "); println(value.(spp[:x]))
=#
# =========================================================================== #

# Collecting the names of instances to solve
#println("\nCollecting...")
#target = "../dat"
#fnames = getfname(target)

#println("\nThat's all folks !")
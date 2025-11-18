#C profits
#A constrants
function heuristicSPP(C, A)

    #we create a matrix  n x m
    n = length(C)           # n variables
    m = size(A, 1)          # m constrants
    x = zeros(Int, n)       # vector of solutions S = {∅}

    # greedy construction
    used_rows = falses(m)   # vector of toke constrancts
    #order = sortperm(C, rev=true)  # we order index of proficts in decreasing order (Not indispensable)
    order = 1:n # natural index order
    for i in order
        rows_of_one = findall(!iszero, A[:, i])  # we create a vector with the number of index in column i that are 1
        if !any(used_rows[rows_of_one])          # if in rows_of_one positions of contrancts vector we don't find true
            x[i] = 1                      # we insert this variable in solution vector S ← S ∪ {i}
            used_rows[rows_of_one] .= true       # we update position of toke constrants
        end
    end

    return x
end

# C: profits
# A: constraints
function heuristicGRASP(C, A, alpha, iter)

    # we create a matrix n x m
    n = length(C)           # n variables
    m = size(A, 1)          # m constraints
    s = zeros(Int, n)       # reset S˚, the best solution found
    sres = 0

    eliteSet = []

    for y in 1:iter

        # S ← greedyRandomizedConstruction(problem, α)

        x = zeros(Int, n)   # solution vector S = {∅}
        used_rows = falses(m)   # vector to track taken constraints
        
        available = collect(1:n)  # candidate indices

        while !isempty(available)

            # compute profit for the still valid candidates
            candidate_values = [C[i] for i in available]

            Cmax = maximum(candidate_values)
            Cmin = minimum(candidate_values)

            # create the Restricted Candidate List (RCL)
            threshold = Cmin + alpha * (Cmax - Cmin)
            RCL = [i for i in available if C[i] >= threshold]

            # if RCL is empty, break
            isempty(RCL) && break

            # pick a candidate randomly from the RCL
            i = rand(RCL)

            # check if it can be inserted (does not violate constraints)
            rows_of_one = findall(!iszero, A[:, i])
            if !any(used_rows[rows_of_one])
                x[i] = 1
                used_rows[rows_of_one] .= true
            end

            # remove the variable from the available list
            deleteat!(available, findfirst(==(i), available))
        end

        # S1 <- localSearchImprovement(S)
        s1, s1res = localSearch_1_1(C, A, x) # x is the heuristic

        # path relinking
        if !isempty(eliteSet)
            (xElite, _) = eliteSet[rand(1:length(eliteSet))]
            sPR, sPRres = pathRelinking(C, A, s1, xElite, eliteSet)
            if sPRres > s1res
                s1 .= sPR
                s1res = sPRres
            end
        end

        # update elite
        push!(eliteSet, (copy(s1), s1res))
        
        # update the global best solution S*
        if s1res > sres
            s .= s1
            sres = s1res
        end
    
    end

    return s, sres
end

# C: profits
# A: constraints
function heuristicGRASPnoImp(C, A, alpha, iter)

    # we create a matrix n x m
    n = length(C)           # n variables
    m = size(A, 1)          # m constraints
    s = zeros(Int, n)       # reset S˚, the best solution found
    sres = 0

    eliteSet = []

    for y in 1:iter

        # S ← greedyRandomizedConstruction(problem, α)

        x = zeros(Int, n)   # solution vector S = {∅}
        used_rows = falses(m)   # vector to track taken constraints
        
        available = collect(1:n)  # candidate indices

        while !isempty(available)

            # compute profit for the still valid candidates
            candidate_values = [C[i] for i in available]

            Cmax = maximum(candidate_values)
            Cmin = minimum(candidate_values)

            # create the Restricted Candidate List (RCL)
            threshold = Cmin + alpha * (Cmax - Cmin)
            RCL = [i for i in available if C[i] >= threshold]

            # if RCL is empty, break
            isempty(RCL) && break

            # pick a candidate randomly from the RCL
            i = rand(RCL)

            # check if it can be inserted (does not violate constraints)
            rows_of_one = findall(!iszero, A[:, i])
            if !any(used_rows[rows_of_one])
                x[i] = 1
                used_rows[rows_of_one] .= true
            end

            # remove the variable from the available list
            deleteat!(available, findfirst(==(i), available))
        end

        # S1 <- localSearchImprovement(S)
        s1, s1res = localSearch_1_1(C, A, x) # x is the heuristic

        # update elite
        push!(eliteSet, (copy(s1), s1res))
        
        # update the global best solution S*
        if s1res > sres
            s .= s1
            sres = s1res
        end
    
    end

    return s, sres
end

# ===========================================================================
# Pure ACO for SPP (no localSearch)
# ===========================================================================

# Weighted random choice without external packages
function weighted_choice(available::Vector{Int}, weights::Vector{Float64})
    if isempty(available)
        error("weighted_choice called with empty available")
    end
    w = copy(weights)
    for i in 1:length(w)
        if !isfinite(w[i]) || w[i] < 0
            w[i] = 0.0
        end
    end
    total = sum(w)
    if total == 0.0
        return available[rand(1:length(available))]
    end
    cumulative = cumsum(w ./ total)
    r = rand()
    idx = findfirst(x -> x >= r, cumulative)
    return available[idx]
end

# Construct solution for one ant
function construct_solution_ant(C::Vector{<:Number}, A::AbstractMatrix,
                                tau::Vector{Float64}, alpha::Float64, beta::Float64)
    n = length(C)
    m = size(A, 1)
    x = zeros(Int, n)
    used_rows = falses(m)
    available = collect(1:n)

    while !isempty(available)
        feas = Int[]
        weights = Float64[]
        for i in available
            rows = findall(!iszero, A[:, i])
            if !any(used_rows[rows])
                push!(feas, i)
                eta = max(1e-9, float(C[i]))
                push!(weights, (tau[i]^alpha) * (eta^beta))
            end
        end
        isempty(feas) && break
        chosen = weighted_choice(feas, weights)
        rows_ch = findall(!iszero, A[:, chosen])
        if !any(used_rows[rows_ch])
            x[chosen] = 1
            used_rows[rows_ch] .= true
        end
        deleteat!(available, findfirst(==(chosen), available))
    end

    return x
end

# Main ACO function (no local search)
function ACO_SPP(C::Vector{<:Number}, A::AbstractMatrix;
                 num_ants::Int=20,
                 num_iter::Int=50,
                 alpha::Float64=1.0,
                 beta::Float64=2.0,
                 rho::Float64=0.1,
                 Q::Float64=1.0)

    n = length(C)
    sumC = sum(float.(C))
    sumC = sumC > 0 ? sumC : 1.0
    tau = ones(Float64, n)   # initial pheromone

    best_global = zeros(Int, n)
    best_global_val = -Inf

    for iter in 1:num_iter
        sols = Vector{Vector{Int}}()
        vals = Float64[]

        for ant in 1:num_ants
            x = construct_solution_ant(C, A, tau, alpha, beta)
            v = sum(C .* x)
            push!(sols, x)
            push!(vals, float(v))
            if v > best_global_val
                best_global_val = v
                best_global .= x
            end
        end

        # evaporate pheromone
        tau .*= (1.0 - rho)

        # deposit pheromone
        for k in 1:length(sols)
            xk = sols[k]
            vk = vals[k]
            if vk <= 0.0
                continue
            end
            delta = (Q * vk) / sumC
            for i in findall(xk .== 1)
                tau[i] += delta
            end
        end

        # elitist deposit
        deltaG = (Q * best_global_val) / sumC
        for i in findall(best_global .== 1)
            tau[i] += 0.5 * deltaG
        end

        println("ACO iter $iter: best_so_far = ", best_global_val)
    end

    return best_global, best_global_val, tau
end

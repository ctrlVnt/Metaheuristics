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

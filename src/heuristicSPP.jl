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

#C profits
#A constrants
function heuristicGRASP(C, A, alpha, iter)

    #we create a matrix  n x m
    n = length(C)           # n variables
    m = size(A, 1)          # m constrants
    s = zeros(Int, n)       # S* best solution found
    sres = 0

    for y in 1:iter

        x = zeros(Int, n) # vector of solutions S = {∅}
        used_rows = falses(m)   # vector of toke constrancts
        
        
        available = collect(1:n)  # indici candidati

        while !isempty(available)

            # Calcola profitto per i candidati ancora validi
            candidate_values = [C[i] for i in available]

            Cmax = maximum(candidate_values)
            Cmin = minimum(candidate_values)

            # Crea la lista RCL (Restricted Candidate List)
            threshold = Cmin + alpha * (Cmax - Cmin)
            RCL = [i for i in available if C[i] >= threshold]

            # Se la RCL è vuota, interrompi
            isempty(RCL) && break

            # Scegli un candidato a caso dalla RCL
            i = rand(RCL)

            # Controlla se può essere inserito (non viola vincoli)
            rows_of_one = findall(!iszero, A[:, i])
            if !any(used_rows[rows_of_one])
                x[i] = 1
                used_rows[rows_of_one] .= true
            end

            # Rimuovi la variabile dall’elenco disponibile
            deleteat!(available, findfirst(==(i), available))
        end

        #S1 <- localSearchImprovement(S)
        s1, s1res = localSearch_1_1(C, A, x) #x is the heuristic
        
        #updateSolution(S1, S*)
        if s1res > sres
            s .= s1
            sres = s1res
        end
    
    end

    return s, sres
end
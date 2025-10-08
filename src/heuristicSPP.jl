#Execrise 1

#C profits
#A constrants
function heuristicSPP(C, A)

    #we create a matrix  n x m
    n = length(C)           # n variables
    m = size(A, 1)          # m constrants
    x = zeros(Int, n)       # vector of solutions S = {∅}

    # greedy construction
    used_rows = falses(m)   # vector of toke constrancts
    order = sortperm(C, rev=true)  # we order index of proficts in decreasing order (Not indispensable)
    #order = 1:n # natural index order
    for i in order
        rows_un = findall(!iszero, A[:, i])  # we create a vector with the number of index in column i that are 1
        if !any(used_rows[rows_un])          # if in rows_un positions of contrancts vector we don't find true
            x[i] = 1                      # we insert this variable in solution vector S ← S ∪ {i}
            used_rows[rows_un] .= true       # we update position of toke constrants
        end
    end

    return x
end
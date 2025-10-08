# Local Search 1-1 (First Improvement)
# C: profit vector
# A: constraint matrix
# x: initial feasible solution (0-1 vector)
function localSearch_1_1(C, A, x)
    n = length(C)        # n variables
    m = size(A, 1)       # n constraints

    current_value = sum(C .* x)   # current value
    improved = true               # flag for while loop

    while improved
        improved = false

        # Try to replace one selected variable (x[i] == 1) with one not selected (x[j] == 0)
        for i in findall(x .== 1)       # candidate indices to remove from solution
            for j in findall(x .== 0)   # candidate indices to add to solution

                # build a new candidate solution by swapping i -> j
                x_new = copy(x)
                x_new[i] = 0
                x_new[j] = 1

                # check feasibility: all constraints must be satisfied (A * x_new <= 1)
                if all((A * x_new) .<= 1)
                    # compute the objective function for the new solution
                    new_value = sum(C .* x_new)
                    # first improvement: accept immediately if better
                    if new_value > current_value
                        x = x_new
                        current_value = new_value
                        improved = true
                        break   # break inner loop (j loop)
                    end
                end
            end
            if improved
                break   # break outer loop (i loop) if improvement was found
            end
        end
    end

    return x, current_value   # return final solution and its objective value
end

# Deepest-Descent Local Search 1-1
function deepestDescent_1_1(C, A, x)
    n = length(C)
    m = size(A, 1)

    current_value = sum(C .* x)
    improved = true

    while improved
        improved = false
        best_value = current_value
        best_move = nothing   # store the best swap (i, j)

        # Explore all 1-1 swaps
        for i in findall(x .== 1)        # candidate to remove
            for j in findall(x .== 0)    # candidate to add
                x_new = copy(x)
                x_new[i] = 0
                x_new[j] = 1

                # feasibility check A matrix and 
                if all((A * x_new) .<= 1)
                    new_value = sum(C .* x_new)
                    # keep the deepest improvement
                    if new_value > best_value
                        best_value = new_value
                        best_move = (i, j)
                    end
                end
            end
        end

        # Apply the best swap if improvement exists
        if best_move !== nothing
            i, j = best_move
            x[i] = 0
            x[j] = 1
            current_value = best_value
            improved = true
        end
    end

    return x, current_value
end

# Deepest-Descent Local Search 2-1
function deepestDescent_2_1(C, A, x)
    n = length(C)
    m = size(A, 1)

    current_value = sum(C .* x)
    improved = true

    while improved
        improved = false
        best_value = current_value
        best_move = nothing

        # Explore all 2-1 swaps
        active = findall(x .== 1)
        inactive = findall(x .== 0)

        for a1 = 1:length(active)-1
            for a2 = a1+1:length(active)
                i1 = active[a1]
                i2 = active[a2]

                for j in inactive
                    x_new = copy(x)
                    x_new[i1] = 0
                    x_new[i2] = 0
                    x_new[j] = 1

                    if all((A * x_new) .<= 1)
                        new_value = sum(C .* x_new)

                        if new_value > best_value
                            best_value = new_value
                            best_move = (i1, i2, j)
                        end
                    end
                end
            end
        end

        if best_move !== nothing
            i1, i2, j = best_move
            x[i1] = 0
            x[i2] = 0
            x[j] = 1
            current_value = best_value
            improved = true
        end
    end

    return x, current_value
end

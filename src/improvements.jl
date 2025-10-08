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

        # Explore all 1-1 swaps
        for i in findall(x .== 1)       # candidate to remove
            for j in findall(x .== 0)   # candidate to add

                # build a new candidate solution by swapping i -> j
                x_new = copy(x)
                x_new[i] = 0
                x_new[j] = 1

                # check feasibility
                if all((A * x_new) .<= 1)

                    new_value = sum(C .* x_new)
                    # first improvement accepted immediately
                    if new_value > current_value
                        x = x_new
                        current_value = new_value
                        improved = true
                        break 
                    end
                end
            end
            if improved
                break 
            end
        end
    end

    return x, current_value
end

# Deepest-Descent Local Search 1-1
function deepestDescent_1_1(C, A, x)
    n = length(C)        # n variables
    m = size(A, 1)       # n constraints

    current_value = sum(C .* x)   # current value
    improved = true               # flag for while loop

    while improved
        improved = false
        best_value = current_value
        best_move = nothing   # store the best swap (i, j)

        # Explore all 1-1 swaps
        for i in findall(x .== 1)        # candidate to remove
            for j in findall(x .== 0)    # candidate to add

                # build a new candidate solution by swapping i -> j
                x_new = copy(x)
                x_new[i] = 0
                x_new[j] = 1

                # check feasibility
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

        # Apply the best swap if improvement exists to x
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
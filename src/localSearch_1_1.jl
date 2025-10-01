#DOESNT WORK

function localSearch_1_1(C, A, x)
    n = length(C)
    m = size(A, 1)

    current_value = sum(C .* x)
    improved = true

    while improved
        improved = false

        # prova a sostituire una variabile scelta con una non scelta
        for i in findall(x .== 1)   # candidate da rimuovere
            for j in findall(x .== 0)  # candidate da aggiungere

                # nuova soluzione candidata
                x_new = copy(x)
                x_new[i] = 0
                x_new[j] = 1

                # controllo ammissibilità: A * x_new <= 1
                if all((A * x_new) .<= 1)
                    new_value = sum(C .* x_new)
                    if new_value > current_value
                        # accetto subito (first improvement)
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

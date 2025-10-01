# Metahuristic

project developed in Julia

## 📚 Julia Functions Used

- length(C) → returns the number of elements in vector C.

- size(A, 1) → returns the number of rows in matrix A (i.e., number of constraints).

- zeros(Int, n) → creates a vector of length n filled with zeros of type Int.

- falses(m) → creates a Boolean vector of length m initialized to false.

- sortperm(C, rev=true) → returns the indices that would sort C in descending order.

- findall(!iszero, A[:, i]) → finds the row indices where column i of A is nonzero.

- any(used_rows[rows_un]) → checks if at least one element in used_rows[rows_un] is true.

- .= (broadcast assignment) → assigns values element-wise to a slice of a vector.
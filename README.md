# Metaheuristics for Set Packing Problem (SPP)

This project implements and compares several metaheuristic algorithms to solve instances of the **Set Packing Problem (SPP)**, a classical combinatorial optimization problem. The goal is to select a subset of items with maximum total profit while respecting packing constraints.

---

## Implemented Heuristics

The following heuristics are implemented and analyzed:

1. **Greedy Heuristic**  
   - Builds a solution iteratively by selecting the item with the highest profit that does not violate constraints.
   - Fast but may yield suboptimal solutions.

2. **GRASP (Greedy Randomized Adaptive Search Procedure)**  
   - Constructs solutions using a **randomized greedy approach** with parameter `alpha` controlling greediness vs randomness.
   - Repeatedly generates solutions to explore the search space.

3. **GRASP + Path Relinking (PR)**  
   - Extends GRASP by performing **path relinking** between elite solutions.
   - Helps intensify the search and find higher-quality solutions.

4. **Ant Colony Optimization (ACO)**  
   - Simulates a colony of ants constructing solutions based on **pheromone trails** and heuristic information (profits).  
   - Pheromone trails are updated iteratively to reinforce good solutions.
   - Can optionally integrate **local search** for solution refinement.

---

## Local Search

All heuristics optionally use **1–1 swap local search**:

- **1–1 Swap:**  
  Iteratively exchanges one selected item with one unselected item if it improves the total profit without violating constraints.
- Can be used standalone or as an improvement phase in GRASP and ACO.

---

## Input Data Format

- A **profit vector `C`** containing the profit of each item.
- A **constraint matrix `A`** where `A[i,j] = 1` if item `j` uses resource `i`.  
- Example:

```
    7 9
    10 5 8 6 9 13 11 4 6
    6
    1 2 3 5 7 8
    3
    2 3 8
```
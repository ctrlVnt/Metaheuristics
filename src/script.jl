# livrableEI1.jl
# Solver for Set Packing Problem (SPP) — Exercise implementation 1
# Single-file entry point. Usage:
# 1) include("livrableEI1.jl")
# 2) resoudreSPP("dat/instance1.dat")
# 3) experimentationSPP()

using Dates
using Random
using Printf
using Serialization

struct SPPInstance
    m::Int           # number of sets
    n::Int           # number of elements
    sets::Vector{Vector{Int}}  # list of sets (1-based element indices)
    weights::Vector{Float64}   # weight/profit per set
    name::String
end

function parse_or_like(filepath::AbstractString)
    txt = read(filepath, String)
    lines = [strip(l) for l in split(txt,'\n') if strip(l) != ""]
    if length(lines) == 0
        error("Empty file: $filepath")
    end
    # Try to parse first line as two ints m n
    header = split(lines[1])
    if length(header) >= 2 && all(x->tryparse(Int,x) !== nothing, header[1:2])
        m = parse(Int, header[1])
        n = parse(Int, header[2])
        sets = Vector{Vector{Int}}()
        weights = Float64[]
        # The following lines may contain mixed data. We'll try two common patterns:
        # Pattern A: each of next m lines: w k i1 i2 ... ik
        # Pattern B: each of next m lines: k i1 i2 ... ik and an earlier line contains weights
        idx = 2
        # collect tokens from rest
        tokens = join(lines[2:end], ' ')
        nums = [x for x in split(tokens) if x != ""]
        # Heuristic: if we have exactly m integers for weights followed by m variable-length sets
        # Try to parse by scanning: if tokens contain many numbers, we'll parse greedily.
        pos = 1
        # Attempt: if next token count matches pattern w k i.., we parse m times
        parsed_sets = Vector{Vector{Int}}()
        parsed_weights = Float64[]
        success = true
        try
            for s in 1:m
                # need at least two tokens: w and k
                if pos + 1 > length(nums); success=false; break; end
                w = parse(Float64, nums[pos]); k = parse(Int, nums[pos+1]);
                pos += 2
                if pos + k -1 > length(nums); success=false; break; end
                items = [parse(Int, nums[pos + j - 1]) for j in 1:k]
                pos += k
                push!(parsed_weights, w)
                push!(parsed_sets, items)
            end
        catch
            success = false
        end
        if success && length(parsed_sets) == m
            return SPPInstance(m,n,parsed_sets,parsed_weights,basename(filepath))
        end
        # Otherwise fallback: assume each of the next m lines is "k items..." and weights absent
        parsed_sets = Vector{Vector{Int}}()
        parsed_weights = Float64[]
        try
            for i in 2:min(length(lines), 1+m)
                numsline = [x for x in split(lines[i]) if x != ""]
                if length(numsline) >= 1
                    k = parse(Int, numsline[1])
                    items = Int[]
                    for j in 1:k
                        if 1 + j > length(numsline)
                            # might continue on next lines: concatenate following lines
                            # simple fallback: scan remaining tokens from whole file
                            break
                        end
                        push!(items, parse(Int, numsline[1+j]))
                    end
                    push!(parsed_sets, items)
                    push!(parsed_weights, 1.0)
                end
            end
            if length(parsed_sets) == m
                return SPPInstance(m,n,parsed_sets,parsed_weights,basename(filepath))
            end
        catch
            # give up
        end
    end
    # Fallback: try simple parsing where each line is a set (items separated by spaces), weights absent
    sets = Vector{Vector{Int}}()
    for l in lines
        toks = [x for x in split(l) if x != ""]
        nums = Int[]
        for t in toks
            v = tryparse(Int,t)
            v !== nothing && push!(nums,v)
        end
        if length(nums) >= 1
            # If first number equals count, skip it
            if length(nums) == nums[1] + 1
                push!(sets, nums[2:end])
            else
                push!(sets, nums)
            end
        end
    end
    m = length(sets)
    n = maximum(vcat([s for s in sets]...))
    weights = ones(Float64, m)
    return SPPInstance(m,n,sets,weights,basename(filepath))
end

# -----------------------------
# Feasibility check & objective
# -----------------------------

function is_feasible_selection(inst::SPPInstance, sel::Vector{Bool})
    covered = zeros(Int, inst.n)
    for j in 1:inst.m
        if sel[j]
            for e in inst.sets[j]
                covered[e] += 1
                if covered[e] > 1
                    return false
                end
            end
        end
    end
    return true
end

function objective(inst::SPPInstance, sel::Vector{Bool})
    s = 0.0
    for j in 1:inst.m
        if sel[j]
            s += inst.weights[j]
        end
    end
    return s
end

# -----------------------------
# Greedy construction
# Strategy: sort sets by weight / |set| descending, add if disjoint
# Return binary selection vector and value
# -----------------------------
function greedy_construct(inst::SPPInstance; rng=Random.GLOBAL_RNG)
    idxs = collect(1:inst.m)
    ratios = [inst.weights[j] / max(1, length(inst.sets[j])) for j in idxs]
    # tie-breaker random shuffle
    perm = sortperm(idxs, by = j->(-ratios[j], rand(rng)))
    selected = falses(inst.m)
    covered = falses(inst.n)
    for j in perm
        can = true
        for e in inst.sets[j]
            if covered[e]
                can = false; break
            end
        end
        if can
            selected[j] = true
            for e in inst.sets[j]
                covered[e] = true
            end
        end
    end
    return selected, objective(inst, selected)
end

# -----------------------------
# Local search: descent using two neighborhoods
# Neighborhood A: 1-1 exchange (remove one selected set, add one non-selected set) if feasible and improves
# Neighborhood B: remove up to k_sel sets and add up to k_add sets (we implement k_sel=2,k_add=1 and k_sel=1,k_add=2)
# We'll implement best-improvement loop: explore neighbors, pick best improving move, repeat until no improvement
# -----------------------------

function neighborhood_1_1(inst::SPPInstance, sel::Vector{Bool})
    best_delta = 0.0
    best_move = nothing # (remove_idx, add_idx)
    current_val = objective(inst, sel)
    # Precompute coverage counts
    cov = zeros(Int, inst.n)
    for j in 1:inst.m
        if sel[j]
            for e in inst.sets[j]
                cov[e] += 1
            end
        end
    end
    for r in 1:inst.m
        if !sel[r]; continue; end
        # try removing r and potentially adding some a
        # compute which elements would become free
        freed = Set{Int}()
        for e in inst.sets[r]
            if cov[e] == 1
                push!(freed, e)
            end
        end
        for a in 1:inst.m
            if sel[a] || a == r; continue; end
            # check if a's elements are compatible after removing r
            ok = true
            for e in inst.sets[a]
                if cov[e] >= 1 && !(e in freed)
                    ok = false; break
                end
            end
            if ok
                delta = inst.weights[a] - inst.weights[r]
                if delta > best_delta + 1e-9
                    best_delta = delta
                    best_move = (r,a)
                end
            end
        end
    end
    return best_delta, best_move
end

function neighborhood_k_p(inst::SPPInstance, sel::Vector{Bool}; k_sel=2, k_add=1)
    # This is a limited enumerative search: enumerate combinations of up to k_sel selected sets to remove
    # and try to add combinations of up to k_add non-selected sets to add that are feasible.
    # For complexity reasons, we restrict to small k_sel,k_add (<=3)
    curval = objective(inst, sel)
    best_delta = 0.0
    best_move = nothing # (remove_vec, add_vec)
    sel_idxs = [i for i in 1:inst.m if sel[i]]
    non_idxs = [i for i in 1:inst.m if !sel[i]]
    using Combinatorics: combinations
    for r in 1:min(k_sel,length(sel_idxs))
        for rem in combinations(sel_idxs,r)
            # compute free elements after removal
            cov = zeros(Int, inst.n)
            for j in 1:inst.m
                if sel[j] && !(j in rem)
                    for e in inst.sets[j]
                        cov[e] += 1
                    end
                end
            end
            # candidate adds up to k_add (we try singletons and pairs if k_add>1)
            max_add = min(k_add, length(non_idxs))
            for a in 1:max_add
                for add in combinations(non_idxs,a)
                    # check feasibility of adding 'add' to current configuration (after removals)
                    ok = true
                    for j in add
                        for e in inst.sets[j]
                            if cov[e] >= 1
                                ok = false; break
                            end
                        end
                        if !ok; break; end
                    end
                    if ok
                        delta = sum(inst.weights[j] for j in add) - sum(inst.weights[j] for j in rem)
                        if delta > best_delta + 1e-9
                            best_delta = delta
                            best_move = (collect(rem), collect(add))
                        end
                    end
                end
            end
        end
    end
    return best_delta, best_move
end

function local_search(inst::SPPInstance, init_sel::Vector{Bool}; rng=Random.GLOBAL_RNG, max_iters=1000)
    sel = copy(init_sel)
    best_val = objective(inst, sel)
    iter = 0
    improved = true
    while improved && iter < max_iters
        iter += 1
        improved = false
        # First neighborhood: 1-1 exchange
        d1, mv1 = neighborhood_1_1(inst, sel)
        # Second neighborhood: (2,1) and (1,2)
        d2, mv2 = neighborhood_k_p(inst, sel, k_sel=2, k_add=1)
        d3, mv3 = neighborhood_k_p(inst, sel, k_sel=1, k_add=2)
        # pick best
        bestd = maximum([d1,d2,d3])
        if bestd > 1e-9
            improved = true
            if bestd == d1
                r,a = mv1
                sel[r] = false; sel[a] = true
            elseif bestd == d2
                rem,add = mv2
                for r in rem; sel[r]=false; end
                for a in add; sel[a]=true; end
            else
                rem,add = mv3
                for r in rem; sel[r]=false; end
                for a in add; sel[a]=true; end
            end
            best_val += bestd
        else
            break
        end
    end
    return sel, best_val, iter
end

# -----------------------------
# Exact solving with JuMP+GLPK/HiGHS
# SPP formulation: maximize sum w_j x_j s.t. for each element i: sum_{j: i in S_j} x_j <= 1, x_j in {0,1}
# -----------------------------

function solve_exact_julia(inst::SPPInstance; solver_name::Symbol=:GLPK)
    if !JUMLIB_AVAILABLE
        error("JuMP or solver not available — install JuMP and GLPK/HiGHS to use exact solving")
    end
    model = Model( (solver_name==:GLPK) ? GLPK.Optimizer : HiGHS.Optimizer )
    set_silent(model)
    @variable(model, x[1:inst.m], Bin)
    @objective(model, Max, sum(inst.weights[j]*x[j] for j=1:inst.m))
    # For each element
    for i in 1:inst.n
        sets_covering = [j for j in 1:inst.m if i in inst.sets[j]]
        if !isempty(sets_covering)
            @constraint(model, sum(x[j] for j in sets_covering) <= 1)
        end
    end
    optimize!(model)
    status = termination_status(model)
    obj = objective_value(model)
    xsol = [round(Int, value(x[j])) for j in 1:inst.m]
    return xsol, obj, status
end

# -----------------------------
# I/O: resoudreSPP(fname) and experimentationSPP()
# -----------------------------

function save_result(fname::AbstractString, res)
    open(fname,"w") do io
        for (k,v) in res
            println(io, @sprintf("%s = %s", k, v))
        end
    end
end

function resoudreSPP(fname::AbstractString)
    println("[SPP] Lecture de l'instance: $fname")
    inst = parse_or_like(fname)
    println("Instance: ", inst.name, ", m=", inst.m, ", n=", inst.n)
    # construction
    t0 = time()
    sel0, val0 = greedy_construct(inst)
    t1 = time()
    println("Greedy value = ", val0, " (CPU = ", round((t1-t0)*1000, digits=1), " ms)")
    # local search
    t0 = time()
    sel1, val1, iters = local_search(inst, sel0)
    t1 = time()
    println("Local search value = ", val1, " (iters=", iters, ", CPU = ", round((t1-t0)*1000, digits=1), " ms)")
    # exact (if available)
    exact_info = nothing
    if JUMLIB_AVAILABLE
        try
            t0 = time()
            xopt, zopt, status = solve_exact_julia(inst, solver_name=:GLPK)
            t1 = time()
            println("Exact (GLPK) z = ", zopt, " status=", status, " CPU = ", round((t1-t0)*1000, digits=1), " ms")
            exact_info = (xopt,zopt,status,(t1-t0))
        catch e
            @warn "Exact solving failed: $e"
        end
    else
        println("JuMP / GLPK not available — exact solving skipped.")
    end
    # save results
    resdir = joinpath(pwd(),"res")
    mkpath(resdir)
    timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
    base = replace(basename(fname), '.' => '_')
    outfile = joinpath(resdir, base*"_res_"*timestamp*".txt")
    resdict = Dict(
        "instance" => inst.name,
        "m" => inst.m,
        "n" => inst.n,
        "greedy_value" => val0,
        "greedy_time_s" => (t1-t0),
        "local_value" => val1,
        "local_time_s" => (t1-t0),
        "local_iters" => iters,
        "exact_info" => exact_info,
        "date" => string(now())
    )
    save_result(outfile, resdict)
    println("Results saved in ", outfile)
    return resdict
end

function experimentationSPP()
    println("Experimental pipeline: solve all .dat files under dat/ (at least 10 recommended)")
    datadir = joinpath(pwd(),"dat")
    files = filter(x->endswith(x, ".dat") || endswith(x, ".txt"), readdir(datadir, join=true))
    if length(files) < 1
        error("No instances found in dat/. Place your .dat files there. Files found: $(files)")
    end
    results = []
    for f in files
        try
            println("Processing ", f)
            r = resoudreSPP(f)
            push!(results, merge(Dict("file"=>f), r))
        catch e
            @warn "Failed on $f: $e"
        end
    end
    # Save aggregated CSV-like
    outcsv = joinpath(pwd(),"res","experimentation_"*Dates.format(now(),"yyyymmdd_HHMMSS")*".csv")
    open(outcsv, "w") do io
        println(io, join(["file","m","n","greedy_value","local_value","date"], ','))
        for r in results
            println(io, join([r["file"], string(r["m"]), string(r["n"]), string(r["greedy_value"]), string(r["local_value"]), r["date"]], ','))
        end
    end
    println("Experiment summary saved to ", outcsv)
    return results
end

# -----------------------------
# Write a README and LaTeX skeleton into doc/
# -----------------------------
function write_docs()
    docdir = joinpath(pwd(),"doc")
    mkpath(docdir)
    readme = """
    README — livrableEI1

    Structure of the archive (root = yourNameEI1):
      src/  : Julian sources (this file)
      dat/  : instances (.dat)
      res/  : results written by resoudreSPP and experimentationSPP
      doc/  : documentation, report template

    Usage:
      cd yourNameEI1
      julia
      include("livrableEI1.jl")
      resoudreSPP("dat/your_instance.dat")
      experimentationSPP()

    Notes:
      - Parser is lenient but may need adaptation depending on the exact OR-library format used.
      - Exact solving requires JuMP and a solver (GLPK or HiGHS) installed.

    """
    open(joinpath(docdir,"README.txt"),"w") do io; write(io, readme); end

    latex = """
    % LaTeX report skeleton for EI1
    \documentclass[11pt]{article}
    \usepackage[utf8]{inputenc}
    \usepackage{amsmath,amssymb,booktabs}
    \title{EI1 — Set Packing Problem: Heuristics and Local Search}
    \author{Votre Nom}
    \date{\today}
    \begin{document}
    \maketitle
    \section{Introduction}
    \section{Modélisation}
    \section{Heuristique de construction}
    \section{Recherche locale}
    \section{Expérimentation}
    \section{Résultats}
    \section{Discussion}
    \section{Conclusion}
    \end{document}
    """
    open(joinpath(docdir,"report_skeleton.tex"),"w") do io; write(io, latex); end
    println("Wrote doc/README.txt and doc/report_skeleton.tex")
end

# write docs at include time
write_docs()

# -----------------------------
# End of livrableEI1.jl
# -----------------------------

println("livrableEI1.jl loaded. Use resoudreSPP(fname) and experimentationSPP().")

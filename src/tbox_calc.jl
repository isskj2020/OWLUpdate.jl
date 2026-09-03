using Graphs, Format, Base.Threads


function prepare_repair_context(ontology::OWLOntology, config::OWLConfig)
    ontology.axioms = append_tbox_root(ontology.axioms)
    nodes = Set{String}()
    push!(nodes, K_OWL_THING)
    for axiom in ontology.axioms
        if axiom isa SubClassOf
            push!(nodes, axiom.subject)
            push!(nodes, axiom.parent)
        elseif axiom isa DisjointWith
            push!(nodes, axiom.subject)
            push!(nodes, axiom.object)
        end
    end
    node_to_id = Dict((n => i) for (i, n) in enumerate(nodes))
    id_to_node = Dict((i => n) for (i, n) in enumerate(nodes))

    dag = SimpleDiGraph(length(nodes), 0)

    for axiom in ontology.axioms
        if axiom isa SubClassOf
            src = node_to_id[axiom.parent]
            dst = node_to_id[axiom.subject]
            add_edge!(dag, src, dst)
        end
    end

    dag = repair_cyclic_graph(dag)

    affected_nodes = Vector{Tuple{Int, Int}}()
    inconsistent_nodes = Set{Int}()
    disjoint_violations = Set{String}()

    for axiom in ontology.axioms
        if axiom isa DisjointWith
            aid = node_to_id[axiom.subject]
            bid = node_to_id[axiom.object]
            a_descendants = dfs_descendants(dag, aid)
            b_descendants = dfs_descendants(dag, bid)
            violated = intersect(a_descendants, b_descendants)

            violated, aid, bid, a_descendants, b_descendants

            union!(inconsistent_nodes, violated)
            if !isempty(violated)
                push!(disjoint_violations, "$axiom")
                for src in violated
                    for dst in find_reachable_node_set(dag, src; bounds = Set([aid, bid]))
                        push!(affected_nodes, (src, dst))
                    end
                end
            end
        end
    end

    return OWLRepairContext(ontology = ontology,
                            config = config,
                            dag = dag,
                            node_to_id = node_to_id,
                            id_to_node = id_to_node,
                            depths = calc_tbox_depths(dag),
                            affected_nodes = affected_nodes,
                            disjoint_violations = disjoint_violations,
                            inconsistent_nodes = inconsistent_nodes)
end

function calc_tbox_depths(dag::SimpleDiGraph)
    depths = Dict{Int, Int}()
    for node in topological_sort(dag)
        parents = inneighbors(dag, node)
        depths[node] = if isempty(parents)
            0
        else
            maximum(depths[parent] + 1 for parent in parents)
        end
    end
    return depths
end

function calculate_repair_cost(ontology::OWLOntology; config = OWLConfig())
    ctx = prepare_repair_context(ontology, config)
    axioms = ontology.axioms

    results = Vector{OWLAxiomResult}(undef, length(axioms))
    @threads for i in eachindex(axioms)
        axiom = axioms[i]
        depth = calc_depth(ctx, axiom)
        violation = calc_violation(ctx, axiom)
        repair_cost = if violation
            axiom.priority * ctx.config.decay_factor^depth
        else
            K_DEFAULT_REPAIR_COST
        end

        results[i] = OWLAxiomResult(id = randstring(32),
                                    axiom = axiom,
                                    depth = depth,
                                    violation = violation,
                                    repair_cost = repair_cost)
    end

    return OWLAnalysis(config = config,
                       ontology = ontology,
                       violation_score = calc_violation_score(results),
                       results = results,)
end


function calculate_violation_scores(ontology::OWLOntology; config = OWLConfig())
    ctx = prepare_repair_context(ontology, config)

    scores = zeros(Int, length(ctx.ontology.axioms))
    for (i, axiom) in enumerate(ctx.ontology.axioms)
        violation = calc_violation(ctx, axiom)
        scores[i] = axiom.priority * Int(violation)
    end
    return scores
end


function calc_depth(ctx::OWLRepairContext, axiom::OWLAxiom)
    node_a, node_b = node_names(axiom)
    aid = ctx.node_to_id[node_a]
    bid = ctx.node_to_id[node_b]
    if axiom isa SubClassOf
        return ctx.depths[bid] + 1
    elseif axiom isa DisjointWith
        return max(ctx.depths[aid], ctx.depths[bid])
    end
    return 0
end

function calc_violation(ctx::OWLRepairContext, axiom::OWLAxiom)
    node_a, node_b = node_names(axiom)
    aid = ctx.node_to_id[node_a]
    bid = ctx.node_to_id[node_b]
    if axiom isa SubClassOf
        return !isempty(filter(x -> x[1] == aid && x[2] == bid, ctx.affected_nodes)) && axiom.parent != K_OWL_THING
    elseif axiom isa DisjointWith
        return "$axiom" in ctx.disjoint_violations
    end
    return false
end

function append_tbox_root(axioms::Vector{OWLAxiom})
    children = Set{String}()
    parents  = Set{String}()
    classes = Set{String}()

    for axiom in axioms
        if axiom isa SubClassOf
            push!(children, axiom.subject)
            push!(parents, axiom.parent)
            push!(classes, axiom.subject)
            push!(classes, axiom.parent)
        elseif axiom isa DisjointWith
            push!(classes, axiom.subject)
            push!(classes, axiom.object)
        end
    end

    roots = setdiff(parents, children)
    isolated = setdiff(classes, union(parents, children))

    new_axioms = Vector{OWLAxiom}(axioms)
    for r in union(roots, isolated)
        if r != K_OWL_THING
            axiom = SubClassOf(subject = r, parent = K_OWL_THING)
            push!(new_axioms, axiom)
        end
    end
    unique!(new_axioms)
    sort!(new_axioms; by = axiom_sort_key)
    return new_axioms
end


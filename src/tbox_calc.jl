using Graphs, Format


function prepare_repair_context(ontology::OWLOntology, config::OWLConfig)
    ontology.axioms = append_tbox_root(ontology.axioms)
    nodes = Vector{String}()
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
    unique!(nodes)
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

function calculate_repair_cost(ontology::OWLOntology; config = OWLConfig())::OWLAnalysis
    ctx = prepare_repair_context(ontology, config)

    results = Vector{OWLAxiomResult}()
    for (i, axiom) in enumerate(ctx.ontology.axioms)
        node_a, node_b = node_names(axiom)
        aid = ctx.node_to_id[node_a]
        bid = ctx.node_to_id[node_b]
        if axiom isa SubClassOf
            depth = ctx.depths[bid] + 1
            violation = !isempty(filter(x -> x[1] == aid && x[2] == bid, ctx.affected_nodes)) && axiom.parent != K_OWL_THING
        elseif axiom isa DisjointWith
            depth = max(ctx.depths[aid], ctx.depths[bid])
            violation = "$axiom" in ctx.disjoint_violations
        end
        repair_cost = if violation
            axiom.priority * ctx.config.decay_factor^depth
        else
            K_DEFAULT_REPAIR_COST
        end

        push!(results, OWLAxiomResult(id = randstring(32),
                                      axiom = axiom,
                                      depth = depth,
                                      violation = violation,
                                      repair_cost = repair_cost))
    end

    nodes = [OWLGraphNode(id = id, inconsistent = id in ctx.inconsistent_nodes) for id in vertices(ctx.dag)]
    edges = Vector{OWLGraphEdge}()
    for result in results
        node_a, node_b = node_names(result.axiom)
        source = ctx.node_to_id[node_a]
        target = ctx.node_to_id[node_b]
        push!(edges, OWLGraphEdge(source = source,
                                 target = target,
                                 violation = result.violation,
                                 type = result.axiom.type,
                                 label = "p=$(format("{:.2f}", result.axiom.priority))"))
    end

    return OWLAnalysis(config = config,
                       ontology = ontology,
                       violation_score = calc_violation_score(results),
                       results = results,
                       nodes = nodes,
                       edges = edges,
                       nodemap = ctx.id_to_node)
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


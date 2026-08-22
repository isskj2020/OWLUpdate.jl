using Random

function parse_owl_toml_tbox_results(dict::AbstractDict)
    results = Vector{OWLAxiomResult}()
    for d in get(dict, K_SUBCLASS_OF, [])
        axiom = SubClassOf(subject = get_value(String, d, "subject", ""),
                           parent = get_value(String, d, "parent", ""),
                           priority = get_value(Float64, d, "priority", K_DEFAULT_PRIORITY))
        depth = get_value(Int, d, "depth", 0)
        violation = get_value(Int, d, "violation", 0) === 1
        repair_cost = get_value(Float64, d, "repair_cost", K_DEFAULT_REPAIR_COST)
        push!(results, OWLAxiomResult(id = randstring(32),
                                      axiom = axiom,
                                      depth = depth,
                                      violation = violation,
                                      repair_cost = repair_cost))
    end
    for d in get(dict, K_DISJOINT_WITH, [])
        axiom = DisjointWith(subject = get_value(String, d, "subject", ""),
                             object = get_value(String, d, "object", ""),
                             priority = get_value(Float64, d, "priority", K_DEFAULT_PRIORITY))
        depth = get_value(Int, d, "depth", 0)
        violation = get_value(Int, d, "violation", 0) === 1
        repair_cost = get_value(Float64, d, "repair_cost", K_DEFAULT_REPAIR_COST)
        push!(results, OWLAxiomResult(id = randstring(32),
                                      axiom = axiom,
                                      depth = depth,
                                      violation = violation,
                                      repair_cost = repair_cost))
    end
    return results
end


function print_toml(io::IO, c::SubClassOf)
    println(io, "subject = \"$(c.subject)\"")
    println(io, "parent = \"$(c.parent)\"")
    println(io, "priority = $(c.priority)")
end

function print_toml(io::IO, c::DisjointWith)
    println(io, "subject = \"$(c.subject)\"")
    println(io, "object = \"$(c.object)\"")
    println(io, "priority = $(c.priority)")
end


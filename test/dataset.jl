using Random, OWLUpdate, DataFrames

const RANDSTR = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
rng = Random.default_rng()

function gen_words(size = 1000)
    words = Vector{String}()
    while length(words) != size
        word = randstring(RANDSTR, 3)
        push!(words, word)
        unique!(words)
    end
    return words
end

function gen_subclass(words::Vector{String})
    axioms = Vector{OWLAxiom}()
    items = deepcopy(words)
    prev = pop!(items)
    while true
        isempty(items) && break
        c1 = pop!(items)
        isempty(items) && break
        c2 = prev
        axiom = OWLUpdate.SubClassOf(subject = c1, parent = c2)
        push!(axioms, axiom)
        prev = c1
    end
    @info "gen_subclass word size:$(length(words)) axioms:$(length(axioms))"
    return axioms
end

function gen_disjoint(tree1::Vector{String}, tree2::Vector{String}, count::Int)
    axioms = Vector{OWLAxiom}()
    size = length(tree1)
    for _ in 1:count
        i = rand(rng, 1:size-1)
        j = rand(rng, i+1:size)
        c1 = tree1[i]
        c2 = tree2[j]
        axiom = OWLUpdate.DisjointWith(subject = c1, object = c2)
        push!(axioms, axiom)
    end
    @info "gen_disjoint tree size 1:$(length(tree1)) 2:$(length(tree2)) count:$count axioms:$(length(axioms))"
    return axioms
end

function gen_cross_subclass(tree1::Vector{String}, tree2::Vector{String}, count::Int)
    axioms = Vector{OWLAxiom}()
    size = length(tree1)
    for _ in 1:count
        i = rand(rng, 1:size-1)
        j = rand(rng, i+1:size)
        c1 = tree1[i]
        c2 = tree2[j]

        axiom = OWLUpdate.SubClassOf(subject = c1, parent = c2)
        push!(axioms, axiom)
    end
    @info "gen_cross_subclass tree size 1:$(length(tree1)) 2:$(length(tree2)) count:$count axioms:$(length(axioms))"
    return axioms
end


function gen_axioms(size::Int, tree_size::Int, cross_count::Int)
    axioms = Vector{OWLAxiom}()
    words = gen_words(size)
    x = div(size, tree_size)
    if tree_size == 2
        tree1 = words[1:x]
        tree2 = words[x+1:2x]
        append!(axioms, gen_subclass(tree1))
        append!(axioms, gen_subclass(tree2))
        append!(axioms, gen_disjoint(tree1, tree2, cross_count))
        append!(axioms, gen_cross_subclass(tree1, tree2, cross_count))
    elseif tree_size == 3
        x = div(size, tree_size)
        tree1 = words[1:x]
        tree2 = words[x+1:2x]
        tree3 = words[2x+1:3x]
        append!(axioms, gen_subclass(tree1))
        append!(axioms, gen_subclass(tree2))
        append!(axioms, gen_subclass(tree3))
        append!(axioms, gen_disjoint(tree1, tree2, cross_count))
        append!(axioms, gen_disjoint(tree2, tree3, cross_count))
        append!(axioms, gen_disjoint(tree3, tree1, cross_count))
        append!(axioms, gen_cross_subclass(tree1, tree2, cross_count))
        append!(axioms, gen_cross_subclass(tree2, tree3, cross_count))
        append!(axioms, gen_cross_subclass(tree3, tree1, cross_count))
    end
    return axioms
end

function create_dataset(name::String, size::Int, tree_size::Int, cross_count::Int)
    config = OWLUpdate.OWLConfig(decay_factor = 0.5)
    iri = "https://github.com/isskj2020/owl-update-sample-data/blob/main/dataset/$name.xml"
    version_iri = "$iri/0.0.1"
    namespaces = Dict{String, String}()
    namespaces["rdfs"] = "http://www.w3.org/2000/01/rdf-schema#"
    namespaces["owl"] = "http://www.w3.org/2002/07/owl#"
    namespaces["xml"] = "http://www.w3.org/XML/1998/namespace"
    namespaces["ex"] = "https://github.com/isskj2020/owl-update-sample-data#"
    namespaces["rdf"] = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    namespaces["xsd"] = "http://www.w3.org/2001/XMLSchema#"

    ontology = OWLOntology(iri = iri,
                version_iri = version_iri,
                axioms = gen_axioms(size, tree_size, cross_count),
                namespaces = namespaces)
    @info "generated axioms: $(length(ontology.axioms))"
    analysis = calculate_repair_cost(ontology; config = config)
    OWLUpdate.save_owl_toml(analysis, "$name.toml")
end

function test_repair_cost()
    config = OWLUpdate.OWLConfig(decay_factor = 0.1)
    ontology = OWLUpdate.parse_owl_toml("./dataset1.toml")

    analysis = calculate_repair_cost(ontology; config = config)

    remove_count = 0

    while analysis.violation_score != 0
        remove_count += 1
        df = DataFrame(analysis.results) |> x -> sort(x, :repair_cost)
        remove_id = first(df).axiom.id
        @info "remove id:" remove_id
        OWLUpdate.delete_axiom!(ontology, remove_id)
        analysis = calculate_repair_cost(ontology; config = config)
    end
    @info "total remove count" remove_count
end


using OWLUpdate, Test, DataFrames, CSV, Base.Threads

@testset "Evaluation Test" begin
    @info "thread size: $(nthreads())"

    include("dataset.jl")
    dataset_name = "dataset1-0.5"
    size = 100
    tree_size = 2
    cross_count = 30
    create_dataset(dataset_name, size, tree_size, cross_count)

    config = OWLUpdate.OWLConfig(decay_factor = 0.5)

    #
    # Repair Strategy
    #
    filename = "$dataset_name-$size-$tree_size-$cross_count-repair"
    ontology = OWLUpdate.parse_owl_toml("./$dataset_name.toml")
    results = NamedTuple[]
    remove_count = 0
    @info "Repair strategy"
    @info "axiom size: $(length(ontology.axioms))"
    open("$filename.txt", "w") do io
        println(io, "total axiom size: $(length(ontology.axioms))")
        println(io, "decay factor: $(config.decay_factor)")
        println(io, "tree size: $tree_size")
        println(io, "subclass cross count: $cross_count")
    end

    analysis = calculate_repair_cost(ontology; config = config)
    while analysis.violation_score != 0
        remove_count += 1

        sort!(analysis.results; by = x -> x.repair_cost)
        deletion = first(analysis.results)

        shapley = calculate_shapley_values(ontology)
        shapley_val = first(filter(x -> x.axiom.id == deletion.axiom.id, shapley.results))

        max_depth = filter(x -> x.violation, analysis.results) |> res -> maximum(x.depth for x in res)

        res = (step = remove_count,
               axiom = deletion.axiom,
               depth = deletion.depth,
               max_depth = max_depth,
               repair_cost = deletion.repair_cost,
               shapley_score = shapley_val.score,
               violation_score = analysis.violation_score)
        @info res
        push!(results, res)

        OWLUpdate.delete_axiom!(ontology, deletion.axiom.id)

        analysis = calculate_repair_cost(ontology; config = config)
    end
    @info "toal remove count: $remove_count"
    CSV.write("$filename.csv", DataFrame(results))

    #
    # Shapley Strategy
    #
    filename = "$dataset_name-$size-$tree_size-$cross_count-shapley"
    ontology = OWLUpdate.parse_owl_toml("./$dataset_name.toml")
    remove_count = 0
    results = NamedTuple[]
    @info "Shapley strategy"
    @info "axiom size: $(length(ontology.axioms))"
    open("$filename.txt", "w") do io
        println(io, "total axiom size: $(length(ontology.axioms))")
        println(io, "decay factor: $(config.decay_factor)")
        println(io, "tree size: $tree_size")
        println(io, "subclass cross count: $cross_count")
    end


    analysis = calculate_repair_cost(ontology; config = config)
    while analysis.violation_score != 0
        remove_count += 1
        shapley = calculate_shapley_values(ontology)

        sort!(shapley.results; by = x -> x.score, rev = true)
        deletion = first(shapley.results)
        repair_val = first(filter(x -> x.axiom.id == deletion.axiom.id, analysis.results))
        @info "deletion: $deletion"

        max_depth = filter(x -> x.violation, analysis.results) |> res -> maximum(x.depth for x in res)

        res = (step = remove_count,
               axiom = deletion.axiom,
               depth = repair_val.depth,
               max_depth = max_depth,
               repair_cost = repair_val.repair_cost,
               shapley_score = deletion.score,
               violation_score = analysis.violation_score)
        @info res
        push!(results, res)

        OWLUpdate.delete_axiom!(ontology, deletion.axiom.id)

        analysis = calculate_repair_cost(ontology; config = config)
    end
    @info "toal remove count: $remove_count"
    CSV.write("$filename.csv", DataFrame(results))
end

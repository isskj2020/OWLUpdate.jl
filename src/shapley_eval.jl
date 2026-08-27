using Random, Base.Threads


@kwdef struct ShapleyResult
    id::String = randstring(32)
    axiom::OWLAxiom
    score::Float64
end

@kwdef struct ShapleyAnalysis
    results::Vector{ShapleyResult}
end


function calculate_shapley_values(ontology::OWLOntology; samples = 1000)
    axioms = ontology.axioms
    n = length(axioms)

    thread_size = nthreads()
    sample_scores = [zeros(Float64, n) for _ in 1:samples]

    @threads for sample in 1:samples
        scores = sample_scores[sample]

        perm = randperm(n)
        subset = OWLAxiom[]
        prev = shapley_eval(ontology, subset)

        for idx in perm
            push!(subset, axioms[idx])
            value = shapley_eval(ontology, subset)
            scores[idx] += value - prev
            prev = value
        end
    end
    scores = reduce(+, sample_scores)
    real_scores = scores ./ samples

    results = Vector{ShapleyResult}()
    for (i, value) in enumerate(real_scores)
        push!(results, ShapleyResult(axiom = axioms[i], score = value))
    end
    return ShapleyAnalysis(results)
end

function shapley_eval(origin::OWLOntology, axioms::Vector{OWLAxiom})
    ontology = OWLOntology(iri = origin.iri,
                           version_iri = origin.version_iri,
                           axioms = axioms,
                           namespaces = origin.namespaces)
    scores = calculate_violation_scores(ontology)
    return sum(scores)
end

using Random

@kwdef mutable struct ShapleyContext <: OWLContext
    ontology::OWLOntology
    samples::Int = 1000
end

@kwdef struct ShapleyResult
    id::String = randstring(32)
    axiom::OWLAxiom
    score::Float64
end

@kwdef struct ShapleyAnalysis
    results::Vector{ShapleyResult}
end


function calculate_shapley_values(ontology::OWLOntology; samples = 1000)
    ctx = ShapleyContext(ontology = ontology, samples = samples)
    axioms = ctx.ontology.axioms
    n = length(axioms)
    scores = zeros(Float64, n)

    for _ in 1:ctx.samples
        perm = randperm(n)
        subset = Vector{OWLAxiom}()
        prev = shapley_eval(ctx, subset)

        for idx in perm
            push!(subset, axioms[idx])
            value = shapley_eval(ctx, subset)
            scores[idx] += value - prev
            prev = value
        end
    end
    real_scores = scores ./ ctx.samples

    results = Vector{ShapleyResult}()
    for (i, value) in enumerate(real_scores)
        push!(results, ShapleyResult(axiom = axioms[i], score = value))
    end
    return ShapleyAnalysis(results)
end

function shapley_eval(ctx::ShapleyContext, axioms::Vector{OWLAxiom})
    ontology = deepcopy(ctx.ontology)
    ontology.axioms = axioms
    analysis = calculate_repair_cost(ontology)
    return analysis.violation_score
end

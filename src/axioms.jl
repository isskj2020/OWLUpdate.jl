using Graphs

const K_OWL_THING = "owl:Thing"
const K_DEFAULT_PRIORITY = 1
const K_DEFAULT_VIOLATION = false
const K_DEFAULT_REPAIR_COST = typemax(Int)
const K_DEFAULT_DECAY_FACTOR = 0.5
const JAR_PATH_OWL_EXTRACTOR = joinpath(@__DIR__, "../owl-extractor/dists/owl-extractor.jar")
const JAR_PATH_OWL_UPDATE = joinpath(@__DIR__, "../owl-extractor/dists/owl-update.jar")
const JAR_PATH_OWL_REASONER = joinpath(@__DIR__, "../owl-extractor/dists/owl-reasoner.jar")

abstract type OWLAxiom end
abstract type OWLContext end

@kwdef mutable struct OWLConfig
    decay_factor::Float64 = K_DEFAULT_DECAY_FACTOR
end

@kwdef mutable struct OWLGraphNode
    id::Int
    inconsistent::Bool
end

@kwdef mutable struct OWLGraphEdge
    source::Int
    target::Int
    violation::Bool
    type::String
    label::String
end

@kwdef mutable struct OWLAxiomResult
    id::String
    axiom::OWLAxiom
    depth::Int64
    violation::Bool
    repair_cost::Float64
end

@kwdef mutable struct OWLOntology
    iri::String
    version_iri::String
    axioms::Vector{OWLAxiom}
    namespaces::Dict{String, String}
end

@kwdef mutable struct OWLAnalysis
    config::OWLConfig
    ontology::OWLOntology
    violation_score::Float64
    results::Vector{OWLAxiomResult}
    nodes::Vector{OWLGraphNode}
    edges::Vector{OWLGraphEdge}
    nodemap::Dict{Int, String}
end

@kwdef mutable struct OWLRepairContext <: OWLContext
    ontology::OWLOntology
    config::OWLConfig
    dag::SimpleDiGraph
    node_to_id::Dict{String, Int}
    id_to_node::Dict{Int, String}
    depths::Dict{Int, Int}
    affected_nodes::Set{Int}
    disjoint_violations::Set{String}
    inconsistent_nodes::Set{Int}
end


function calc_violation_score(results::Vector{OWLAxiomResult})
    violation_score = 0.0
    for res in results
        violation_score += res.axiom.priority * res.violation
    end
    return violation_score
end

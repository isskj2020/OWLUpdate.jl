using Random

const K_SUBCLASS_OF = "subClassOf"
const K_DISJOINT_WITH = "disjointWith"

@kwdef mutable struct SubClassOf <: OWLAxiom
    id::String = randstring(32)
    sort_key::Int = 1
    type::String = K_SUBCLASS_OF
    subject::String
    parent::String
    priority::Float64 = K_DEFAULT_PRIORITY
end

Base.show(io::IO, x::SubClassOf) = print(io, "$(x.subject) ⊑ $(x.parent), p=$(x.priority)")
axiom_sort_key(x::SubClassOf) = (x.sort_key, x.parent, x.subject)
node_names(x::SubClassOf) = (x.subject, x.parent)

@kwdef mutable struct DisjointWith <: OWLAxiom
    id::String = randstring(32)
    sort_key::Int = 2
    type::String = K_DISJOINT_WITH
    subject::String
    object::String
    priority::Float64 = K_DEFAULT_PRIORITY
end

Base.show(io::IO, x::DisjointWith) = print(io, "$(x.subject) ⊓ $(x.object) = ∅, p=$(x.priority)")
axiom_sort_key(x::DisjointWith) = (x.sort_key, x.subject, x.object)
node_names(x::DisjointWith) = (x.subject, x.object)


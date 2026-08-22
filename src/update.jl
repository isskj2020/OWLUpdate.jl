
function delete_axiom!(ontology::OWLOntology, id::String)
    file_id = string(uuid1())
    removed_axioms = filter(x -> x.id == id, ontology.axioms)
    new_axioms = filter(x -> x.id !== id, ontology.axioms)
    ontology.axioms = new_axioms
    return removed_axioms
end

function save_removed_axioms(ontology::OWLOntology, axioms::Vector{OWLAxiom}, filepath::String)
    open(filepath, "w") do io
        print_toml(io, ontology)
        println(io)
        for axiom in axioms
            println(io, "[[$(axiom.type)]]")
            print_toml(io, axiom)
            println(io)
        end
    end
end

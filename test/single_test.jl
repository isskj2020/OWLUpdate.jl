using OWLUpdate, Test

@testset "Single Test" begin
    xml_filepath = "./sample1.xml"
    new_xml_filepath = "./sample1.changed.xml"
    toml_filepath = "./sample1.toml"
    removed_filepath = "./out.sample1.removed.toml"

    results = reason_owl_xml(xml_filepath)
    @info "reasoner:" results

    ontology = parse_owl_xml(xml_filepath)
    @info "IRI" ontology.iri
    analysis = calculate_repair_cost(ontology)
    @info "analysis size" length(analysis.results)
    @info "violation score" analysis.violation_score

    removed_axioms = delete_axiom!(ontology, ontology.axioms[1].id)

    save_removed_axioms(ontology, removed_axioms, removed_filepath)

    @test isfile(removed_filepath)

    analysis = calculate_repair_cost(ontology)
    @info "analysis size" length(analysis.results)
    @info "violation score" analysis.violation_score

    save_owl_toml(analysis, toml_filepath)

    @test isfile(toml_filepath)

    apply_changes_owl_xml(xml_filepath, removed_filepath, new_xml_filepath)

    @test isfile(new_xml_filepath)

    rm(new_xml_filepath)
    rm(toml_filepath)
    rm(removed_filepath)
end

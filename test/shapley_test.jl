using OWLUpdate, Test

@testset "Shapley Test" begin
    xml_filepath = "./sample1.xml"

    ontology = parse_owl_xml(xml_filepath)
    @info "IRI" ontology.iri

    shapley_analysis = calculate_shapley_values(ontology)
    @info "shapley" shapley_analysis
end

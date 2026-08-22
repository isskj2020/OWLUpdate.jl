using OWLUpdate, Test

rm("./sample-data"; force = true, recursive = true)
run(`git clone -b develop git@github.com:isskj2020/owl-update-sample-data.git sample-data`)

test_dirs = ["sample-data/sample"]

for dir in test_dirs
    @testset "test: $dir" begin
        for file in readdir(dir)
            @info file
            segments = splitext(file)
            if segments[2] === ".toml"
                ontology = parse_owl_toml(joinpath(dir, file))
                @info "TOML IRI" ontology.iri
                analysis = calculate_repair_cost(ontology)
                @info "analysis size" length(analysis.results)
                @info "violation score" analysis.violation_score
            elseif segments[2] === ".xml"
                ontology = parse_owl_xml(joinpath(dir, file))
                @info "IRI" ontology.iri
                analysis = calculate_repair_cost(ontology)
                @info "analysis size" length(analysis.results)
            end
        end
    end
end

rm("./sample-data"; force = true, recursive = true)

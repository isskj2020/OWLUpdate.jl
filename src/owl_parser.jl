using Dates, UUIDs, Random, TOML, OrderedCollections

function parse_owl_xml(filepath::String)
    file_id = string(uuid1())
    toml_filepath = joinpath("$file_id.toml")
    run(`java -jar $JAR_PATH_OWL_EXTRACTOR $filepath $toml_filepath`)
    dict = TOML.parse(open(toml_filepath, "r"))
    rm(toml_filepath)
    return parse_owl_toml(dict)
end

function parse_owl_toml(filepath::String)
    dict = TOML.parse(open(filepath, "r"))
    return parse_owl_toml(dict)
end

function parse_owl_toml(dict::AbstractDict)
    iri = ""
    version_iri = ""
    for (k, v) in get(dict, "ontology", Dict())
        if k === "IRI"
            iri = v
        end
        if k === "versionIRI"
            version_iri = v
        end
    end
    namespaces = OrderedDict{String, String}()
    for (k, v) in get(dict, "namespaces", Dict())
        namespaces[k] = v
    end

    results = Vector{OWLAxiomResult}()
    append!(results, parse_owl_toml_tbox_results(dict))
    axioms = map(x -> x.axiom, results)

    sort!(namespaces)
    sort!(axioms; by = axiom_sort_key)

    return OWLOntology(iri = iri,
                       version_iri = version_iri,
                       axioms = axioms,
                       namespaces = namespaces)
end

function save_owl_toml(analysis::OWLAnalysis, filepath::String)
    open(filepath, "w") do io
        print_toml(io, analysis.ontology)
        println(io)
        println(io, "[status]")
        println(io, "violation_score = $(analysis.violation_score)")
        println(io, "decay_factor = $(analysis.config.decay_factor)")
        println(io)

        for result in analysis.results
            println(io, "[[$(result.axiom.type)]]")
            print_toml(io, result.axiom)
            println(io, "violation = $(Int(result.violation))")
            println(io, "depth = $(result.depth)")
            println(io, "repair_cost = $(result.repair_cost)")
            println(io)
        end
    end
end

function apply_changes_owl_xml(target_filepath::String, removed_filepath::String, output_filepath::String)
    run(`java -jar $JAR_PATH_OWL_UPDATE $target_filepath $removed_filepath $output_filepath`)
end


function print_toml(io::IO, x::OWLOntology)
    println(io, "[ontology]")
    println(io, "IRI = \"$(x.iri)\"")
    println(io, "versionIRI = \"$(x.version_iri)\"")
    println(io)

    println(io, "[namespaces]")
    for (k, v) in x.namespaces
        println(io, "$k = \"$v\"")
    end
    println(io)
end

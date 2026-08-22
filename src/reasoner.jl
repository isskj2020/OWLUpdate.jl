using JSON

function reason_owl_xml(filepath::String)
    file_id = string(uuid1())
    json_filepath = "$file_id.json"
    run(`java -jar $JAR_PATH_OWL_REASONER $filepath $json_filepath`)

    results = JSON.parse(open(json_filepath, "r"))
    rm(json_filepath)
    return results
end


# A TOML-based OWL update tool.

It uses the OWL API to extract the OWL axioms required for updates from XML using owl-extractor.jar.
Based on the TOML required for the update, it calculates continuous priorities and repair costs,
and performs ontology updates using the TOML representation. The resulting changes are then applied
back to the OWL XML.

# Installation
```julia
pkg> add https://github.com/isskj2020/OWLUpdate.jl
```

# Basic Functions

```julia
using OWLUpdate

# load XML
ontology = parse_owl_xml(xml_filepath)
# load TOML
ontology = parse_owl_toml(toml_filepath)

# calculate
analysis = calculate_repair_cost(ontology)

# update
removed_axioms = delete_axiom!(ontology, ontology.axioms[1].id)
save_removed_axioms(ontology, removed_axioms, removed_toml_filepath)
analysis = calculate_repair_cost(ontology)

# save

save_owl_toml(analysis, toml_filepath)
apply_changes_owl_xml(xml_filepath, removed_filepath, new_xml_filepath)

```

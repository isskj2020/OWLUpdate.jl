package com.owlupdate.toml;

import java.util.Map;

import org.semanticweb.owlapi.model.OWLOntologyID;

public class Metadata implements TomlAxiom {

    private String iri;
    private String versionIRI;
    private Map<String, String> namespaces;

    public Metadata(OWLOntologyID ontologyID, Map<String, String> namespaces) {
        iri = ontologyID.getOntologyIRI().map(x ->  x.getIRIString()).orElse("");
        versionIRI = ontologyID.getVersionIRI().map(x ->  x.getIRIString()).orElse("");
        this.namespaces = namespaces;
    }

    @Override
    public String toToml() {
        StringBuilder sb = new StringBuilder();
        sb.append("[ontology]\n");
        sb.append(String.format("IRI = \"%s\"\n", iri));
        sb.append(String.format("versionIRI = \"%s\"\n", versionIRI));
        sb.append("\n");

        sb.append("[namespaces]\n");
        namespaces.forEach((key, value) -> {
            String prefix = key.replaceAll(":", "").replaceAll("xmlns", "");
            if (prefix.length() > 0) {
                sb.append(String.format("\"%s\" = \"%s\"\n", prefix, value));
            }
        });
        sb.append("\n");
        return sb.toString();
    }

    @Override
    public String sortKey(int level) {
        return "0";
    }
    
}

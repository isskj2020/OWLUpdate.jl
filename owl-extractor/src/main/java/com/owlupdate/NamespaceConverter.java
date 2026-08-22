package com.owlupdate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.semanticweb.owlapi.formats.PrefixDocumentFormat;
import org.semanticweb.owlapi.formats.RDFXMLDocumentFormat;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLException;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyID;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.tomlj.TomlParseResult;
import org.tomlj.TomlTable;

import com.owlupdate.toml.Metadata;
import com.owlupdate.toml.TomlAxiom;

public class NamespaceConverter {

    private final OWLOntologyManager manager;
    private PrefixDocumentFormat prefixFormat = new RDFXMLDocumentFormat();
    private OWLOntologyID ontologyID = new OWLOntologyID(IRI.create(""));

    public NamespaceConverter(OWLOntologyManager manager) {
        this.manager = manager;
    }

    public PrefixDocumentFormat getFormat() {
        return prefixFormat;
    }

    public OWLOntologyID getOntologyID() {
        return ontologyID;
    }

    public void setPrefixes(OWLOntology ontology) {
        ontologyID = ontology.getOntologyID();
        HashMap<String, String> newPrefixes = new HashMap<String, String>();
        newPrefixes.putAll(manager.getOntologyFormat(ontology)
                .asPrefixOWLDocumentFormat()
                .getPrefixName2PrefixMap());
        newPrefixes.putAll(prefixFormat.getPrefixName2PrefixMap());
        RDFXMLDocumentFormat newFormat = new RDFXMLDocumentFormat();
        newFormat.copyPrefixesFrom(newPrefixes);
        prefixFormat = newFormat.asPrefixOWLDocumentFormat();
    }

    public String shortIRI(IRI iri) {
        return prefixFormat.getPrefixIRI(iri);
    }

    public String getIRI(String iri) {
        String[] kv = iri.split(":");
        if (kv.length != 2) return iri;
        String prefix = kv[0] + ":";

        Map<String, String> namespaces = namespaces();
        if (namespaces.containsKey(prefix)) {
            return namespaces.get(prefix) + kv[1];
        }
        return iri;
    }

    public List<TomlAxiom> convertTo() {
        return List.of(new Metadata(ontologyID, namespaces()));
    }

    public void readFromToml(TomlParseResult result) throws OWLException {
        TomlTable tomlOntology = result.getTable("ontology");
        String iri = tomlOntology.getString("IRI");
        String versionIRI = tomlOntology.getString("versionIRI");
        ontologyID = new OWLOntologyID(IRI.create(iri), IRI.create(versionIRI));

        TomlTable namespaces = result.getTable("namespaces");
        HashMap<String, String> prefixes = new HashMap<>();
        for (String key : namespaces.keySet()) {
            prefixes.put(key+":", namespaces.getString(key));
        }

        prefixFormat.copyPrefixesFrom(prefixes);
    }

    public Map<String, String> namespaces() {
        if (prefixFormat == null) {
            return Map.of();
        }
        Map<String, String> prefixes = prefixFormat.getPrefixName2PrefixMap();
        return prefixes;
    }
}

package com.owlupdate;

import java.nio.file.Path;
import java.nio.file.Paths;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.tomlj.Toml;
import org.tomlj.TomlParseResult;

public class OWLGenerator {

    public static void main(String[] args) throws Exception {

        if (args.length != 2) {
            System.err.println(
                "Usage: java -jar owl-toml2xml.jar <input.toml> <output.xml>"
            );
            System.exit(1);
            return;
        }

        Path input = Paths.get(args[0]);
        Path output = Paths.get(args[1]);
        OWLOntologyManager manager = OWLManager.createOWLOntologyManager();
        NamespaceConverter namespaces = new NamespaceConverter(manager);

        TomlParseResult result = Toml.parse(input);
        namespaces.readFromToml(result);

        OWLOntology ontology = manager.createOntology(namespaces.getOntologyID());
        namespaces.setPrefixes(ontology);

        TBoxConverter tbox = new TBoxConverter(manager, namespaces);

        if (result.contains("subClassOf")) {
            tbox.addSubClassOf(result.getArray("subClassOf"), ontology);
        }
        if (result.contains("disjointWith")) {
            tbox.addDisjointWith(result.getArray("disjointWith"), ontology);
        }

        manager.saveOntology(ontology, namespaces.getFormat(), IRI.create(output.toFile()));
    }
}

package com.owlupdate;

import java.nio.file.Path;
import java.nio.file.Paths;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.tomlj.Toml;
import org.tomlj.TomlParseResult;

public class OWLUpdate {

    public static void main(String[] args) throws Exception {

        if (args.length != 3) {
            System.err.println(
                "Usage: java -jar owl-update.jar <target.xml> <remove.toml> <output.xml>"
            );
            System.exit(1);
            return;
        }

        Path xmlFile = Paths.get(args[0]);
        Path tomlFile = Paths.get(args[1]);
        Path outputXmlFile = Paths.get(args[2]);

        OWLOntologyManager manager = OWLManager.createOWLOntologyManager();
        OWLOntology ontology = manager.loadOntologyFromOntologyDocument(xmlFile.toFile());

        NamespaceConverter namespaces = new NamespaceConverter(manager);
        namespaces.setPrefixes(ontology);

        TomlParseResult result = Toml.parse(tomlFile);
        namespaces.readFromToml(result);

        TBoxConverter tbox = new TBoxConverter(manager, namespaces);

        if (result.contains("subClassOf")) {
            tbox.removeSubClassOf(result.getArray("subClassOf"), ontology);
        }
        if (result.contains("disjointWith")) {
            tbox.removeDisjointWith(result.getArray("disjointWith"), ontology);
        }

        manager.saveOntology(ontology, namespaces.getFormat(), IRI.create(outputXmlFile.toFile()));
    }
}

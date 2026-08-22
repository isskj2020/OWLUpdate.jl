package com.owlupdate;

import java.io.FileWriter;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.OWLDisjointClassesAxiom;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.semanticweb.owlapi.model.OWLSubClassOfAxiom;
import com.owlupdate.toml.TomlAxiom;

public class OWLExtractor {

    public static void main(String[] args) throws Exception {

        if (args.length != 2) {
            System.err.println(
                "Usage: java -jar owl-extractor.jar <input.xml> <output.toml>"
            );
            System.exit(1);
            return;
        }

        Path input = Paths.get(args[0]);
        Path output = Paths.get(args[1]);

        OWLOntologyManager manager = OWLManager.createOWLOntologyManager();
        OWLOntology ontology = manager.loadOntologyFromOntologyDocument(input.toFile());
        FileWriter writer = new FileWriter(output.toFile());
        List<TomlAxiom> tomlAxioms = new ArrayList<>();

        NamespaceConverter namespaces = new NamespaceConverter(manager);
        namespaces.setPrefixes(ontology);
        tomlAxioms.addAll(namespaces.convertTo());
        TBoxConverter tbox = new TBoxConverter(manager, namespaces);

        ontology.axioms().forEach(axiom -> {
            if (axiom instanceof OWLSubClassOfAxiom x) {
                tomlAxioms.addAll(tbox.convertTo(x));
            } else if (axiom instanceof OWLDisjointClassesAxiom x) {
                tomlAxioms.addAll(tbox.convertTo(x));
            }
        });
        try {
            tomlAxioms.sort(Comparator
                .comparing((TomlAxiom x) -> x.sortKey(0))
                .thenComparing(x -> x.sortKey(1)));
            writer.write(tomlAxioms.stream().map(x -> x.toToml()).collect(Collectors.joining()));
            writer.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

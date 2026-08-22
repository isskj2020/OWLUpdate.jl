package com.owlupdate;

import java.io.FileWriter;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import org.semanticweb.HermiT.Configuration;
import org.semanticweb.HermiT.Reasoner;
import org.semanticweb.owlapi.apibinding.OWLManager;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.semanticweb.owlapi.reasoner.InferenceType;
import com.google.gson.Gson;

public class OWLReasoner {

    public static void main(String[] args) throws Exception {

        if (args.length != 2) {
            System.err.println(
                "Usage: java -jar owl-reasoner.jar <input.xml> <output.json>"
            );
            System.exit(1);
            return;
        }

        Path input = Paths.get(args[0]);
        Path output = Paths.get(args[1]);
        OWLOntologyManager manager = OWLManager.createOWLOntologyManager();
        OWLOntology ontology = manager.loadOntologyFromOntologyDocument(input.toFile());
        Configuration configuration = new Configuration();
        Reasoner reasoner = new Reasoner(configuration, ontology);
        reasoner.precomputeInferences(InferenceType.CLASS_HIERARCHY);

        List<String> classes = ontology.classesInSignature()
        .filter(x -> !reasoner.isSatisfiable(x))
        .map(x -> x.getIRI().getIRIString()).toList();

        String json = new Gson().toJson(classes);

        FileWriter writer = new FileWriter(output.toFile());

        try (writer) {
            writer.write(json);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}

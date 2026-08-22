package com.owlupdate;

import java.util.ArrayList;
import java.util.List;

import org.semanticweb.owlapi.model.AddAxiom;
import org.semanticweb.owlapi.model.IRI;
import org.semanticweb.owlapi.model.OWLClass;
import org.semanticweb.owlapi.model.OWLClassExpression;
import org.semanticweb.owlapi.model.OWLDataFactory;
import org.semanticweb.owlapi.model.OWLDisjointClassesAxiom;
import org.semanticweb.owlapi.model.OWLOntology;
import org.semanticweb.owlapi.model.OWLOntologyManager;
import org.semanticweb.owlapi.model.OWLSubClassOfAxiom;
import org.semanticweb.owlapi.model.RemoveAxiom;
import org.tomlj.TomlArray;
import org.tomlj.TomlTable;

import com.owlupdate.toml.DisjointWith;
import com.owlupdate.toml.SubClassOf;
import com.owlupdate.toml.TomlAxiom;

public class TBoxConverter {

    private final OWLOntologyManager manager;
    private final NamespaceConverter namespaces;

    public TBoxConverter(OWLOntologyManager manager, NamespaceConverter namespaces) {
        this.manager = manager;
        this.namespaces = namespaces;
    }

    public List<TomlAxiom> convertTo(OWLSubClassOfAxiom axiom) {
        OWLClassExpression subclass = axiom.getSubClass();
        OWLClassExpression parent = axiom.getSuperClass();
        if (!subclass.isNamed() || !parent.isNamed()) return List.of();
        String s1 = namespaces.shortIRI(subclass.asOWLClass().getIRI());
        String s2 = namespaces.shortIRI(parent.asOWLClass().getIRI());
        return List.of(new SubClassOf(s1, s2));
    }

    public void addSubClassOf(TomlArray array, OWLOntology ontology) {
        OWLDataFactory df = manager.getOWLDataFactory();
        int size = array.size();
        for (int i = 0; i < size; i++) {
            TomlTable item = array.getTable(i);
            String subject = item.getString("subject");
            String parent = item.getString("parent");
            String subjectIRI = namespaces.getIRI(subject);
            String parentIRI = namespaces.getIRI(parent);
            OWLClass c1 = df.getOWLClass(IRI.create(subjectIRI));
            OWLClass c2 = df.getOWLClass(IRI.create(parentIRI));
            AddAxiom add = new AddAxiom(ontology, df.getOWLSubClassOfAxiom(c1, c2));
            manager.applyChange(add);
        }
    }

    public void removeSubClassOf(TomlArray array, OWLOntology ontology) {
        OWLDataFactory df = manager.getOWLDataFactory();
        int size = array.size();
        for (int i = 0; i < size; i++) {
            TomlTable item = array.getTable(i);
            String subject = item.getString("subject");
            String parent = item.getString("parent");
            String subjectIRI = namespaces.getIRI(subject);
            String parentIRI = namespaces.getIRI(parent);
            OWLClass c1 = df.getOWLClass(IRI.create(subjectIRI));
            OWLClass c2 = df.getOWLClass(IRI.create(parentIRI));
            RemoveAxiom remove = new RemoveAxiom(ontology, df.getOWLSubClassOfAxiom(c1, c2));
            manager.applyChange(remove);
        }
    }

    public List<TomlAxiom> convertTo(OWLDisjointClassesAxiom axiom) {
        List<TomlAxiom> tomls = new ArrayList<>();
        List<OWLClassExpression> list = axiom.classExpressions().toList();
        int size = list.size();
        for (int i = 0; i < size; i++) {
            for (int j = i + 1; j < size; j++) {
                String s1 = namespaces.shortIRI(list.get(i).asOWLClass().getIRI());
                String s2 = namespaces.shortIRI(list.get(j).asOWLClass().getIRI());
                tomls.add(new DisjointWith(s1, s2));
            }
        }
        return tomls;
    }

    public void addDisjointWith(TomlArray array, OWLOntology ontology) {
        OWLDataFactory df = manager.getOWLDataFactory();
        int size = array.size();
        for (int i = 0; i < size; i++) {
            TomlTable item = array.getTable(i);
            String subject = item.getString("subject");
            String object = item.getString("object");
            String subjectIRI = namespaces.getIRI(subject);
            String objectIRI = namespaces.getIRI(object);
            OWLClass c1 = df.getOWLClass(IRI.create(subjectIRI));
            OWLClass c2 = df.getOWLClass(IRI.create(objectIRI));
            AddAxiom add = new AddAxiom(ontology, df.getOWLDisjointClassesAxiom(c1, c2));
            manager.applyChange(add);
        }
    }

    public void removeDisjointWith(TomlArray array, OWLOntology ontology) {
        OWLDataFactory df = manager.getOWLDataFactory();
        int size = array.size();
        for (int i = 0; i < size; i++) {
            TomlTable item = array.getTable(i);
            String subject = item.getString("subject");
            String object = item.getString("object");
            String subjectIRI = namespaces.getIRI(subject);
            String objectIRI = namespaces.getIRI(object);
            OWLClass c1 = df.getOWLClass(IRI.create(subjectIRI));
            OWLClass c2 = df.getOWLClass(IRI.create(objectIRI));
            RemoveAxiom remove = new RemoveAxiom(ontology, df.getOWLDisjointClassesAxiom(c1, c2));
            manager.applyChange(remove);
        }
    }
}

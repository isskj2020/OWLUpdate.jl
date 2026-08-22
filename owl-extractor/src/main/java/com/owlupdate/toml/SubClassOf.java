package com.owlupdate.toml;

public class SubClassOf implements TomlAxiom {
    
    private String subject;
    private String parent;

    public SubClassOf(String s1, String s2) {
        subject = s1;
        parent = s2;
    }

    @Override
    public String toToml() {
        StringBuilder sb = new StringBuilder();
        sb.append("[[subClassOf]]\n");
        sb.append(String.format("subject = \"%s\"\n", subject));
        sb.append(String.format("parent = \"%s\"\n", parent));
        sb.append("\n");
        return sb.toString();
    }

    @Override
    public String sortKey(int level) {
        if (level == 0) return "100";
        return subject;
    }
}

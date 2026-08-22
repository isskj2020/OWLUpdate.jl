package com.owlupdate.toml;

public class DisjointWith implements TomlAxiom {
    
    private String subject;
    private String object;

    public DisjointWith(String s1, String s2) {
        subject = s1;
        object = s2;
    }

    @Override
    public String toToml() {
        StringBuilder sb = new StringBuilder();
        sb.append("[[disjointWith]]\n");
        sb.append(String.format("subject = \"%s\"\n", subject));
        sb.append(String.format("object = \"%s\"\n", object));
        sb.append("\n");
        return sb.toString();
    }

    @Override
    public String sortKey(int level) {
        if (level == 0) return "200";
        return subject;
    }
}

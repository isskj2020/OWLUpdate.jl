package com.owlupdate.toml;

public interface TomlAxiom {
    String sortKey(int level);
    String toToml();
}

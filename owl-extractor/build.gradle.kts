plugins {
    java
    id("com.gradleup.shadow") version "9.3.0"
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.tomlj:tomlj:1.1.1")
    implementation("net.sourceforge.owlapi:owlapi-distribution:5.5.1")
    implementation("net.sourceforge.owlapi:org.semanticweb.hermit:1.4.5.519")
    implementation("com.google.code.gson:gson:2.14.0")
    implementation("org.slf4j:slf4j-nop:2.0.17")
}

tasks.register<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar>("owl-extractor-jar") {
    archiveBaseName = "owl-extractor"
    from(sourceSets.main.map { it.output })
    configurations = project.configurations.runtimeClasspath.map { listOf(it) }
    manifest {
        attributes(mapOf("Main-Class" to "com.owlupdate.OWLExtractor"))
    }
}

tasks.register<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar>("owl-generator-jar") {
    archiveBaseName = "owl-generator"
    from(sourceSets.main.map { it.output })
    configurations = project.configurations.runtimeClasspath.map { listOf(it) }
    manifest {
        attributes(mapOf("Main-Class" to "com.owlupdate.OWLGenerator"))
    }
}

tasks.register<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar>("owl-update-jar") {
    archiveBaseName = "owl-update"
    from(sourceSets.main.map { it.output })
    configurations = project.configurations.runtimeClasspath.map { listOf(it) }
    manifest {
        attributes(mapOf("Main-Class" to "com.owlupdate.OWLUpdate"))
    }
}

tasks.register<com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar>("owl-reasoner-jar") {
    archiveBaseName = "owl-reasoner"
    from(sourceSets.main.map { it.output })
    configurations = project.configurations.runtimeClasspath.map { listOf(it) }
    manifest {
        attributes(mapOf("Main-Class" to "com.owlupdate.OWLReasoner"))
    }
}
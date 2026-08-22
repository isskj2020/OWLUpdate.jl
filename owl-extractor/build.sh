#!/bin/bash

./gradlew build owl-extractor-jar owl-generator-jar owl-update-jar owl-reasoner-jar
rm -rf dists && mkdir dists
cp build/libs/owl-extractor.jar dists/
cp build/libs/owl-generator.jar dists/
cp build/libs/owl-update.jar dists/
cp build/libs/owl-reasoner.jar dists/


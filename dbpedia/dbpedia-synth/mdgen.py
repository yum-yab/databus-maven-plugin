#! /bin/python3

# this script id for generating the .md files in the databus structure for dbpedia-synth

import xml.dom.minidom as minidom
import sys
import os 
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("sourcedir", help="The source-directory. Here schould be the directorys like mappings and generic.")
args = parser.parse_args()


for src in os.listdir(args.sourcedir):
    typeid=src.replace("-synth","")
    if os.path.isfile(args.sourcedir+"/"+src+"/pom.xml"):
        maindir=args.sourcedir+"/"+src
        for artifact in os.listdir(maindir):
            if os.path.isdir(maindir+"/"+artifact):
                originArtifact= artifact
                mdfile = open(maindir+"/"+artifact+"-synth.md", "w")
                mdfile.write("The synthetic data generated from "+"https://databus.dbpedia.org/dbpedia/"+typeid+"/"+originArtifact)


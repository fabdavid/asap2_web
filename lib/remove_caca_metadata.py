#!/usr/bin/env python3.6

# This script expands the SCope formatted Clusterings and Embeddings into their
# own column attributes to make them available in other tools such as ASAP.

# Provide one argument, a loom file

import h5py
import sys

loom_path = sys.argv[1]

with h5py.File(loom_path,  "a") as f:
	if "/row_attrs/APC" in f: del f["/row_attrs/APC"]
	if "/row_attrs/00010 Glycolysis " in f: del f["/row_attrs/00010 Glycolysis "]
	if "/row_attrs/C19" in f: del f["/row_attrs/C19"]
	if "/row_attrs/Cell cycle - G1" in f: del f["/row_attrs/Cell cycle - G1"]
	if "/row_attrs/Cell cycle - G2" in f: del f["/row_attrs/Cell cycle - G2"]
	if "/row_attrs/DNA polymerase alpha " in f: del f["/row_attrs/DNA polymerase alpha "]
	if "/row_attrs/H" in f: del f["/row_attrs/H"]
	if "/row_attrs/HRD1" in f: del f["/row_attrs/HRD1"]
	if "/row_attrs/Heme biosynthesis, glutamate => protoheme" in f: del f["/row_attrs/Heme biosynthesis, glutamate => protoheme"]
	if "/row_attrs/Ketone body biosynthesis, acetyl-CoA => acetoacetate" in f: del f["/row_attrs/Ketone body biosynthesis, acetyl-CoA => acetoacetate"]
	if "/row_attrs/MAPK (ERK1" in f: del f["/row_attrs/MAPK (ERK1"]
	if "/row_attrs/NADH dehydrogenase (ubiquinone) Fe-S protein" in f: del f["/row_attrs/NADH dehydrogenase (ubiquinone) Fe-S protein"]
	if "/row_attrs/Pantothenate biosynthesis, valine" in f: del f["/row_attrs/Pantothenate biosynthesis, valine"]
	if "/row_attrs/Pyrimidine deoxyribonuleotide biosynthesis, CDP" in f: del f["/row_attrs/Pyrimidine deoxyribonuleotide biosynthesis, CDP"]
	if "/row_attrs/Pyrimidine ribonucleotide biosynthesis, UMP => UDP" in f: del f["/row_attrs/Pyrimidine ribonucleotide biosynthesis, UMP => UDP"]
	if "/row_attrs/Riboflavin biosynthesis, GTP => riboflavin" in f: del f["/row_attrs/Riboflavin biosynthesis, GTP => riboflavin"]
	if "/row_attrs/Spliceosome, Prp19" in f: del f["/row_attrs/Spliceosome, Prp19"]
	if "/row_attrs/Spliceosome, U4" in f: del f["/row_attrs/Spliceosome, U4"]
	if "/row_attrs/Valine" in f: del f["/row_attrs/Valine"]
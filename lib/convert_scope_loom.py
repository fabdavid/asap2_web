#!/usr/bin/env python3
#
# This script expands the SCope formatted Clusterings and Embeddings into their
# own column attributes to make them available in other tools such as ASAP.
#
# Provide one argument, a loom file
#
import loompy as lp
import json
import os
import numpy as np
import sys
#
loom_path = sys.argv[1]
#
with lp.connect(loom_path, validate=False) as fh:
#
    meta = json.loads(ds.attrs['MetaData'])
#
    for embedding in meta['embeddings']:
        attr_name = f"Embedding_{''.join(x if x.isalnum() else '_' for x in embedding['name'])}"
        ds.ca[attr_name] = np.array([x for x in zip(ds.ca['Embeddings_X'][embedding['id']], ds.ca['Embeddings_Y'][embedding['id']])])
#
#
    for clustering in meta['clusterings']:
        attr_name = f"Clustering_{''.join(x if x.isalnum() or x == '.' else '_' for x in clustering['name'])}"
        ds.ca[attr_name] = ds.ca['Clusterings'][str(clustering['id'])]

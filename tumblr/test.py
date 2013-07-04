#!/usr/bin/python

import pyindx as index

index.simpairs()

# images with most similarities:
most_sim=sorted(index.Tum.imgs.values()[:], key=lambda p:len(p.relates))[::-1]
most_sim=filter(lambda p:len(p.relates)>1, most_sim)
index.savehtml(most_sim, '.groups.html')

# dubletten
index.searchdoubles()

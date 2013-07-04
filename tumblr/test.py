#!/usr/bin/python

import pyindx as index

index.simpairs()
# images with most similarities:
most_sim=sorted(index.Tum.imgs.values()[:], key=lambda p:len(p.relates))
most_sim=filter(lambda p:len(p.relates)>0, most_sim)
index.saveshtml(most_sim, '.groups.html')

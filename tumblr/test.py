#!/usr/bin/python

import pyindx as index

index.simpairs()

# images with most similarities:
most_sim=sorted(index.Tum.imgs.values()[:], key=lambda p:len(p.relates))[::-1]
most_sim=filter(lambda p:len(p.relates)>1, most_sim)
print "Save similarity groupd to html"
index.savehtml(most_sim, '.groups.html')
print "Save similarity walk through to html"
index.stumblr(most_sim[0], '.stumblr.html')
#cliques=index.cliques()
#index.savegroups(cliques, '.cliques.html')

# dubletten
index.searchdoubles()

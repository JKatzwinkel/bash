#!/usr/bin/python

import util.statistics as stats

# computes the similarity of two picture's histograms
# based on Pearson coefficient
def hist_sim(p, q):
	# asume number color tones has been reduced to 64 by Picture class
	# if those two pictures are not in the same colorspace, thats no prob
	# while the first one might visit its B, G, and R histograms, the other
	# one just stays in its black'n'white space.
	# handle maximum colorspace, however
	colspace=sorted([p.mode, q.mode], key=lambda m:len(m))[-1]
	offset=0
	correlations=[]
	for band in colspace:
		corr=stats.pearson(p.histogram[offset:], q.histogram[offset:])
		correlation.insert(0, corr)
		offset-=64
	# now how do we put them together?
	res=sum(correlations)/len(correlations)
	return res
	

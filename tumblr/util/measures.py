#!/usr/bin/python

from math import sqrt as sqr
from random import randrange as rnd
import util.statistics as stats

# computes the similarity of two picture's histograms
# based on Pearson coefficient
def image_histograms(p, q):
	# asume number color tones has been reduced to 32 by Picture class
	# if those two pictures are not in the same colorspace, thats no prob
	# while the first one might visit its B, G, and R histograms, the other
	# one just stays in its black'n'white space.
	# handle maximum colorspace, however
	colspace=sorted([p.mode, q.mode], key=lambda m:len(m))[-1]
	correlations=[]
	for offset,band in enumerate(colspace):
		off1=offset*32%len(p.histogram)
		off2=offset*32%len(q.histogram)
		corr=stats.pearson(p.histogram[off1:off1+32], q.histogram[off2:off2+32])
		correlations.append(corr)
	# now how do we put them together?
	#res=sum(correlations)/len(correlations)
	return correlations
	

# computes the medians for the histogram channels of an image
def image_histmediane(p):
	mediane=[]
	for offset,channel in enumerate('RGB'):
		off=offset*32%len(p.histogram)
		band=p.histogram[off:off+32]
		#median=sum([i*v for (i,v) in enumerate(band)])/sum(band)
		median=stats.median_histogram(band)
		mediane.append(median)
	return mediane


# gibt einen abstand der farbaussteuerungen
# zurueck
def image_histmediandist(p,q):
	mediane=[image_histmediane(p), image_histmediane(q)]
	dists=map(lambda (x,y):sqr((x-y)**2), zip(mediane[0], mediane[1]))
	dist=sum(dists)/32.
	return dist

# wie bunt?
def image_histrelcol(p):
	hist=p.histogram
	#print len(hist), p.name
	scale=p.histoscale
	res=[]
	if len(hist)>32:
		grey=[sum(
			[hist[i],hist[(i+32)%len(hist)],
			hist[(i+64)%len(hist)]])*scale/3 for i in range(32)]
		for bank in range(3):
			res.extend(
				[scale*v-grey[i] for (i,v) in enumerate(hist[bank*32:(bank+1)*32])])
	else:
		for bank in range(3):
			res.extend([hist[i]/(i-17.5) for i in range(32)])
	return res


# korrelier das
def image_histrelcor(p,q):
	corrs=[]
	rel=[image_histrelcol(p), image_histrelcol(q)]
	for bank in range(0,96,32):
		cor=stats.pearson(rel[0][bank:bank+32], rel[1][bank:bank+32])
		corrs.append(cor)
	return corrs

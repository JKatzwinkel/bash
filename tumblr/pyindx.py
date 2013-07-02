#!/usr/bin/python

from PIL import Image as pil
import os
from utils import statistics as stat

# scales a given array down to half its size
def scalehalf(array):
	return map(lambda (x,y):(x-y)**2, zip(array[::2], array[1::2]))



##########################3 CLASSES ###########################3
# featured Image
class Tum:
	imgs={}
	def __init__(self, path, name):
		self.path=path
		self.name=name
		self.sources=[]
		self.info="<unknown>"
		self.size=(0,0)
		self.histogram=[]
		filename=os.sep.join([self.path, self.name])
		try:
			self.pict=pil.open(filename)
			self.info='{0}'.format(self.pict.size)
			self.size=self.pict.size
			self.histogram=self.pict.histogram()
			del self.pict
		except:
			print filename, 'broken' 
			#os.remove(filename)
		# scale down histogram
		ratio=len(self.histogram)/32
		hist=[sum(self.histogram[i*ratio:(i+1)*ratio]) for i in range(0,32)]
		#self.histogram=[v/ratio for v in hist]
		#while len(self.histogram)>32:
			#self.histogram=scalehalf(self.histogram)
		norm=max(hist)/255.
		self.histogram=[int(v/norm) for v in hist]
		Tum.imgs[name]=self
		#print '\r{0}'.format(len(Tum.imgs)),

	def show(self):
		print self.sources
		self.pict=pil.open(os.sep.join([self.path, self.name]))
		self.pict.show()
		del self.pict
	
	@property
	def origin(self):
		return self.sources[0]
	
	# calculates similarity measure between two images
	def similarity(self, pict):
		# distance of sizes
		#dim=sum(map(lambda (x,y):(x-y)**2, zip(self.size, pict.size)))
		#dim/=self.size[0]**2+self.size[1]**2
		dimensions=zip(self.size, pict.size)
		widths=sorted(dimensions[0])
		heights=sorted(dimensions[1])
		sim=1.*widths[0]/widths[1]*heights[0]/heights[1]
		#hst=sum(map(lambda (x,y):(x-y)**2, zip(self.histogram, pict.histogram)))
		hstcor=stat.pearson(self.histogram, pict.histogram)
		sim*=hstcor
		return sim
	
	# finds related images
	def similar(self, n=10):
		sim=[]
		hosts=[t for t in self.sources]
		while hosts != [] and len(sim)<n*10:
			host=hosts.pop(0)
			hosts.extend(host.relates)
			sim.extend(host.popular)
		sim=list(set(sim))
		if self in sim:
			sim.remove(self)
		sim.sort(key=lambda x:self.similarity(x), reverse=True)
		return sim[:n]
	
	
	def __repr__(self):
		if len(self.sources) > 0:
			return '<{0}, orig: {1} ({2} src)>'.format(
				self.info, self.sources[0], len(self.sources))
		return '<{0} - No record> '.format(self.info)
	
	#simple histogram representation
	@property
	def hist(self):
		return ''.join([" _.-~'^`"[v/36] for v in self.histogram])


# Blog
class Blr:
	blogs={}
	def __init__(self, name):
		self.name=name
		self.relates=set()
		self.features=set()
		Blr.blogs[name]=self
	
	# interlinks this blog with another one
	def link(self, blogname):
		b2=Blr.blogs.get(blogname)
		if b2:
			self.relates.add(b2)
			b2.relates.add(self)
	
	# prints out implied connections to blogs
	def linked(self):
		for l in self.relates:
			print ' {0} <--> {1}'.format(self, l)
	
	# interlinks a blog and an image
	def feature(self, img):
		pict = Tum.imgs.get(img)
		if pict:
			self.features.add(pict)
			pict.sources.append(self)
		else:
			self.features.add(img)
	
	@property
	def feat(self):
		return [i for i in self.features if isinstance(i, Tum)]
	
	# returns hosted images ordered by popularity
	@property
	def popular(self):
		pop=self.feat
		pop.sort(key=lambda p:len(p.sources), reverse=True)
		return pop

	def __repr__(self):
		return '<{0}: {1}img, {2}cnx>'.format(
			self.name.split('.')[0], len(self.features), len(self.relates))


# return an instance for a blog name
def tumblr(name):
	t=Blr.blogs.get(name)
	if t:
		return t
	return Blr(name)

# return pictures ordered by size
def largest():
	l=[p for p in Tum.imgs.values()]
	l.sort(key=lambda p:p.size[0]*p.size[1], reverse=True)
	return l




#############################################################3
################    MODULE FUNCTIONS    ######################
#############################################################3


def init():
	# instantiate img objects for all images on disk
	for path, dirs, files in os.walk('.'):
		if path.endswith('/img'):
			for img in files:
				Tum(path, img)
	# for the entire source record
	for entry in open('sources'):
		img, blogs = entry.split(' ')
		blogobj=[]
		# connect image to each blog that featured it and viceversa
		for t in blogs.split(','):
			blr=tumblr(t)
			blr.feature(img)
			blogobj+=[blr]
		# link all blogs featuring this image to each other
		for t in blogobj:
			t.relates=t.relates.union(set(blogobj))
			t.relates.remove(t)
	pictures=Tum.imgs.values()
	return pictures
	
pictures=init()
pictures.sort(key=lambda x:len(x.sources))
pictures.reverse()

tumblrs=Blr.blogs.values()
tumblrs.sort(key=lambda x:len(x.features))
tumblrs.reverse()



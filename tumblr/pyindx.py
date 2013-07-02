#!/usr/bin/python

from PIL import Image as pil
import os
from random import choice
from utils import statistics as stat

# scales a given array down to half its size
def scalehalf(array):
	return map(lambda (x,y):(x-y)**2, zip(array[::2], array[1::2]))



##########################3 CLASSES ###########################3
# featured Image
class Tum:
	imgs={}
	def __init__(self, path, name, slots={}):
		self.path=path
		self.name=name
		self.sources=[]
		self.info="<unknown>"
		self.mode=slots.get('mode','None')
		self.size=slots.get('size',(0,0))
		self.histogram=slots.get('histogram', [])
		if len(self.histogram) < 1:
			filename=os.sep.join([self.path, self.name])
			try:
				self.pict=pil.open(filename)
				self.size=self.pict.size
				self.mode=self.pict.mode
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
		self.info='{0} {1}'.format(self.size, self.mode)
		Tum.imgs[name]=self
		#print '\r{0}'.format(len(Tum.imgs)),

	def show(self):
		print self.sources
		self.pict=pil.open(os.sep.join([self.path, self.name]))
		self.pict.show()
		del self.pict
	
	
	@property
	def location(self):
		return os.sep.join([self.path, self.name])
	
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
		hosts=self.sources[:]
		sim.extend([choice(Tum.imgs.values()) for i in range(n*2)])
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

#create or retrieve a picture
def picture(path, name):
	res=Tum.imgs.get(name)
	if not res:
		res=Tum(path,name)
	return res

def getpict(name):
	return Tum.imgs.get(name)


###########################################################33
# Blog
class Blr:
	blogs={}
	def __init__(self, name):
		self.name=name.split('.')[0]
		self.relates=set()
		self.features=set()
		Blr.blogs[self.name]=self
	
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
			self.name, len(self.features), len(self.relates))


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

# writes the locations of the images in the given list to a file
def saveset(filename, images):
	f=open(filename,'w')
	for p in images:
		f.write('{0}\n'.format(p.location))
	f.close()

def savehtml(filename, images):
	f=open(filename, 'w')
	f.write('<html>\n<body>')
	for p in images:
		f.write('\t<img src="{}"/><br/>\n'.format(p.location))
		f.write('\t{}\n'.format(p.origin.name))
	f.close()

# computes similarity matrix for list of images
# also, prints it!
def matrix(images):
	M=[[None]*len(images) for i in images]
	for i in range(len(images)):
		for j in range(i,len(images)):
			sim=int(images[i].similarity(images[j])*100)
			M[j][i]=sim
			M[i][j]=sim
	labels=['{0} {1}'.format(p.origin.name, p.info) for p in images]
	margin=max([len(label) for label in labels])
	align='{0}'.format(margin)
	# print
	print ' '*(6+margin),' '.join(
		['{:3}'.format(i) for i in range(len(images))])
	print ' '*(5+margin),'-'*(len(images)*4)
	for i in range(len(images)):
		row='{:2}. {:'+align+'s} : {}'
		vector=' '.join(['{:3}'.format(sim) for sim in M[i]])
		print row.format(i, labels[i], vector)
	

# save image info
def save(filename='.images'):
	f=open(filename,'w')
	for p in Tum.imgs.values():
		histdump=''.join([hex(v)[2:] for v in p.histogram])
		width, height = p.size
		f.write('{0} {4} {1}x{2} {3} \n'.format(
			p.location, width, height, histdump, p.mode))
	f.close()

# load from image info record
def load(filename='.images'):
	f=open(filename,'r')
	for line in f:
		fields=line.split(' ')
		if len(fields)>5:
			print 'wrong data layout'
			f.close()
			return
		locs=fields[0].split(os.sep)
		path=os.sep.join(locs[:-1])
		name=locs[-1]
		mode=fields[1]
		dim=fields[2].split('x')
		size=(int(dim[0]), int(dim[1]))
		histogram=[]
		dump=fields[3]
		for i in range(0,len(dump),2):
			histogram.append(int(dump[i:i+2], 16))
		Tum(path, name, slots={'size':size, 'histogram':histogram, 'mode':mode})
	f.close()

# initialize from file system and sources files
def init():
	# instantiate img objects for all images on disk
	for path, dirs, files in os.walk('.'):
		if path.endswith('/img'):
			for img in files:
				picture(path, img)
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
	
try:
	load()
except Exception, e:
	print 'Failed loading image information'
	print e.args
	print e.message
	
pictures=init()
pictures.sort(key=lambda x:len(x.sources))
pictures.reverse()

tumblrs=Blr.blogs.values()
tumblrs.sort(key=lambda x:len(x.features))
tumblrs.reverse()



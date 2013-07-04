#!/usr/bin/python

from PIL import Image as pil
import os
from random import choice
from math import sqrt as sqr
import util.statistics as stat
import util.measures as measure

# scales a given array down to half its size
def scalehalf(array):
	return map(lambda (x,y):x+y, zip(array[::2], array[1::2]))



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
		self.histoscale=slots.get('histoscale', 1)
		if len(self.histogram) < 1:
			filename=os.sep.join([self.path, self.name])
			try:
				self.pict=pil.open(filename)
				self.size=self.pict.size
				self.mode=self.pict.mode
				self.histogram=self.pict.histogram()
				del self.pict
				#os.remove(filename)
				# scale down histogram
				#ratio=len(self.histogram)/96
				#hist=[sum(self.histogram[i*ratio:(i+1)*ratio]) for i in range(0,32)]
				#self.histogram=[v/ratio for v in hist]
				#while len(self.histogram)>32:
				hist=self.histogram[:]
				for i in [1,2,3]:
					if len(hist)>96 or self.mode != 'RGB':
						hist=scalehalf(hist) # scale histogram down to 32re tones
				norm=max(hist)/255.
				if norm>1:
					self.histogram=[int(v/norm) for v in hist]
					self.histoscale=int(norm)
				else:
					self.histogram=hist[:]
				if self.mode=='RGBA':
					self.histogram=self.histogram[:96]
					self.mode='RGB'
			except:
				print filename, 'broken' 
		self.info='{0} {1}'.format(self.size, self.mode)
		self.relates={}
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
		if len(self.sources)>0:
			return self.sources[0]
		return None
	
	# calculates similarity measure between two images
	# -1: negative correlation, 1: perfect correlation/identity
	def similarity(self, pict):
		# distance of sizes
		#dim=sum(map(lambda (x,y):(x-y)**2, zip(self.size, pict.size)))
		#dim/=self.size[0]**2+self.size[1]**2
		msr=[]
		dimensions=zip(self.size, pict.size)
		widths=sorted(dimensions[0])
		heights=sorted(dimensions[1])
		msr.append(sqr(1.*widths[0]/widths[1]*heights[0]/heights[1]))
		#hst=sum(map(lambda (x,y):(x-y)**2, zip(self.histogram, pict.histogram)))
		hstcor=measure.image_histograms(self, pict)
		msr.extend(hstcor)
		mood=measure.image_histmediandist(self, pict)
		msr.append(1-mood)
		colorful=measure.image_histrelcor(self, pict)
		msr.extend(colorful)
		return sum(msr)/len(msr)
	
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
		ann=[(p,self.similarity(p)) for p in sim]
		for p,sm in ann:
			if sm>.85:
				connect(self,p,sm)
		ann.sort(key=lambda x:x[1], reverse=True)
		return ann[:n]

	# look how two pictures are related
	def compare(self, pict):
		sim=self.similarity(pict)
		if sim>.85:
			connect(self,pict,sim)
		print 'Similarity: {:2.3f}'.format(sim)
		print 'Color mood dist: {:2.3f}'.format(
			measure.image_histmediandist(self, pict))
		for p in [self, pict]:
			print '\tInfo:     \t{}'.format(p.info)
			print '\tNamespace:\t{}'.format(p.path)
			print '\tFilename: \t{}'.format(p.name)
			print '\tHistogram:\t{}'.format(p.hist)
			print '\tSources:\n\t\t',
			for source in p.sources:
				print source.name,
			print 
	
	def __repr__(self):
		if len(self.sources) > 0:
			return '<{0}, orig: {1} ({2} src)>'.format(
				self.info, self.sources[0], len(self.sources))
		return '<{0} - No record> '.format(self.info)
	
	#simple histogram representation
	@property
	def hist(self):
		res=[]
		for thresh in [200,150,100,50,25,0]:
			row=[[' ','.',':'][int(v>thresh)+int(v>thresh+15)] for v in
				self.histogram]
			res.append(''.join(row))
		return "\n".join(res)
		#return ''.join([" _.-~'^`"[v/36] for v in self.histogram])

#create or retrieve a picture
def picture(path, name):
	res=Tum.imgs.get(name)
	if not res:
		res=Tum(path,name)
	if not os.path.exists(res.location):
		del Tum.imgs[name]
		res=None
	return res

def getpict(name):
	return Tum.imgs.get(name)

# establishes a link between two pictures
def connect(p,q,sim):
	p.relates[q]=sim
	q.relates[p]=sim



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
def saveset(images, filename):
	f=open(filename,'w')
	for p in images:
		f.write('{0}\n'.format(p.location))
	f.close()

def savehtml(images, filename):
	f=open(filename, 'w')
	f.write('<html>\n<body>')
	for p in images:
		f.write(' <div>\n')
		f.write('  <h3>{}</h3/>\n'.format(p.name))
		f.write('  <table height="{}">\n'.format(p.size[1]))
		f.write('   <tr><td rowspan="2">\n')
		f.write('    <img src="{}"/><br/>\n'.format(p.location))
		if p.origin:
			f.write('   <br/>{}>\n'.format(p.origin.name))
		f.write('   </td>\n')

		thmbsize=min(p.size[1]/2, 300)
		for i,s in enumerate(p.relates.keys()):
			f.write('     <td>\n')
			f.write('      <img src="{}" height="{}"><br/>\n'.format(s.location, thmbsize))
			if (s.origin):
				f.write('      {}\n'.format(s.origin.name))
			f.write('     </td>\n')
			if i==len(p.relates)/2:
				f.write('    </tr><tr>\n')
		f.write('   </tr>\n  </table>\n')
		f.write(' </div>/n')
	f.write('</body>\n</html>\n')
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
	labels=['{0} {1}'.format(
		['',p.origin.name][int(p.origin!=None)], p.info) for p in images]
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



# looks for images with 100% similarity
def searchdoubles():
	res=[]
	imgs=Tum.imgs.values()
	for i in range(len(imgs)):
		for j in range(i+1,len(imgs)):
			p=imgs[i]
			q=imgs[j]
			sim=p.similarity(q)
			if sim>.86:
				connect(p,q,sim)
				if sim>.92:
					#print 'High similarity between {} and {}.'.format(p,q)
					res.append((p,q,sim))
					if p.origin:
						p.origin.link(q)
	f=open('.aliases.html','w')
	f.write('<html>\n<body>')
	res.sort(key=lambda t:t[2], reverse=True)
	for p,q,sim in res:
		f.write('<h4>{} and {}: {}</h4>\n'.format(p.name,q.name,sim))
		f.write('<b>{} versus {}: </b><br/>\n'.format(p.info,q.info,))
		if len(p.sources)>0 and len(q.sources)>0:
			f.write('<i>{} and {}: </i><br/>\n'.format(p.origin.name,q.origin.name,))
		f.write('<img src="{}"/><img src="{}"/><br/>\n'.format(
			p.location, q.location))
	f.write('</body>\n</html>\n')
	f.close()
	print len(res), 'potential aliases'
	return res


def simpairs():
	res=[]
	imgs=Tum.imgs.values()
	for i in range(len(imgs)):
		for j in range(i+1,len(imgs)):
			p=imgs[i]
			q=imgs[j]
			sim=p.similarity(q)
			if sim>.87 and sim<.98:
				res.append((p,q,sim))
				connect(p,q,sim)
	f=open('.twins.html','w')
	f.write('<html>\n<body>')
	res.sort(key=lambda t:t[2], reverse=True)
	for p,q,sim in res[:500]:
		f.write('<h4>{} and {}: {}</h4>\n'.format(p.name,q.name,sim))
		f.write('<b>{} versus {}: </b><br/>\n'.format(p.info,q.info,))
		if len(p.sources)>0 and len(q.sources)>0:
			f.write('<i>{} and {}: </i><br/>\n'.format(p.origin.name,q.origin.name,))
		f.write('<img src="{}"/><img src="{}"/><br/>\n'.format(
			p.location, q.location))
	f.write('</body>\n</html>\n')
	f.close()
	return res
	
	

# save image info
def save(filename='.images'):
	f=open(filename,'w')
	for p in Tum.imgs.values():
		histdump=''.join([hex(v)[2:] for v in p.histogram])
		width, height = p.size
		f.write('{0} {4} {1}x{2} {3} {5} \n'.format(
			p.location, width, height, histdump, p.mode, p.histoscale))
	f.close()

# load from image info record
def load(filename='.images'):
	f=open(filename,'r')
	for line in f:
		fields=line.split(' ')
		if len(fields)>10:
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
		histoscale=int(fields[4])
		Tum(path, name, slots={
			'size':size, 'histogram':histogram, 'mode':mode,
			'histoscale':histoscale})
	f.close()

# initialize from file system and sources files
def init():
	print "Begin reading directory content and origin information"
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
	print "Done!"
	pictures=Tum.imgs.values()
	return pictures
	
try:
	print "Try to load index dump"
	load()
except Exception, e:
	print 'Failed loading image information'
	print e.args
	print e.message
	

pictures=init()
pictures.sort(key=lambda x:len(x.sources))
pictures.reverse()

tumblrs=Blr.blogs.values()[:]
tumblrs.sort(key=lambda x:len(x.feat), reverse=True)



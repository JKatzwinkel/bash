#!/usr/bin/python

from PIL import Image as pil
import os

# featured Image
class Tum:
	imgs={}
	def __init__(self, path, name):
		self.path=path
		self.name=name
		self.sources=[]
		self.info="<unknown>"
		self.size=(0,0)
		filename=os.sep.join([self.path, self.name])
		try:
			self.pict=pil.open(filename)
			self.info='{0}'.format(self.pict.size)
			self.size=self.pict.size
			del self.pict
		except:
			print filename, 'broken' 
			os.remove(filename)
		Tum.imgs[name]=self

	def show(self):
		print self.sources
		self.pict=pil.open(os.sep.join([self.path, self.name]))
		self.pict.show()
		del self.pict
	
	@property
	def origin(self):
		return self.sources[0]
	
	# finds related images
	def similar(self):
		sim=[]
		for s in self.sources:
			popular
	
	
	def __repr__(self):
		if len(self.sources) > 0:
			return '<{0}, orig: {1} ({2} src)>'.format(
				self.info, self.sources[0], len(self.sources))
		return '<{0} - No record> '.format(self.info)

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



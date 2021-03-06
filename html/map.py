#!/usr/bin/python
import os
import sys
import cgi
from math import log10 as log

_names=[]
_diskusage={}
_baseurl = 'https://192.168.178.1/wiki/doku.php?id='
_documentroot = '/var/lib/dokuwiki/data/pages'

# http://wiki.python.org/moin/HowTo/Sorting/ 
# http://stackoverflow.com/questions/955941/how-to-identify-whether-a-file-is-normal-file-or-directory-using-python
# http://stackoverflow.com/questions/1392413/calculating-a-directory-size-using-python

def is_child_dir(namespace, entry):
	# entry is subdirectory if and only if no separators remain
	# after removing prepending higher directory path
	if entry[1] == '':
		if namespace==':':
			namespace=''
			if not entry[0].startswith(':'):
				entry[0] = ':'+entry[0]
		if entry[0].startswith(namespace+':'):
			return len(':'.join(entry[0].split(namespace+':')[1:]).split(':')) is 1
	return False

# For the specified directory, return a list of the contained files ans 
# immediate subdirectories, sorted by disk space consumption and 
# beginning with the directory itself, followed by its largest child
def largest(dirname):
	return filter(lambda x:x[0] == dirname or is_child_dir(dirname, x), _names)

# Return disk space consumption of the resource under the given path.
# If referencing a directory, the return value is computed by summing up
# the disk_usage values of the contained resources recursively.
# (That is, look up in the dictionary that has been populated during
# the initial bottom-up tree walk in resources())
# If it is a file, simply return its file size.
def disk_usage(path):
	if os.path.isdir(path):
		return _diskusage.get(path, 0)
	else:
		return os.path.getsize(path)


# makes the given path relative to _documentroot
def relpath(path):
	res = os.path.relpath(path, _documentroot)
	if res == '.':
		return ':'
	return ':'.join(['']+res.split(os.sep))


def resources(dirname):
	results=[]
	if not os.path.isdir(dirname):
		return results
	# walk bottom-up
	for dirname, subdirs, files in os.walk(dirname, topdown=False):
		du = 0 
		# disk usage of sub directories
		for sd in subdirs:
			filesize = disk_usage(os.path.join(dirname, sd))
			du += filesize
		 #disk usage of contained files
		for fn in filter(lambda x:x.endswith('.txt'), files):
			filesize = disk_usage(os.path.join(dirname, fn))
			du += filesize
			results.append( (relpath(dirname), fn.split('.txt')[0], filesize) )
		results.append( (relpath(dirname), '', du+1) )
		# save directory disk use in dictionary
		_diskusage[dirname] = du+1
	return sorted(results, key=lambda x:x[2], reverse=True)


def partition(dirname, level=0):
	partitions = largest(dirname)
	if len(partitions) < 1:
		print dirname
		return
	full = partitions[0][2]
	#print " "*level, dirname, full
	for part in partitions[1:]:
		size = part[2]
		if part[1] == '':
			try:
				partition(part[0], level+1)
			except Exception:
				print part, dirname
		else:
			print " "*(level+1), part[1], 100*size/full
		full -= size


# ========== RENDERING SECTION =========== #
def indent(level):
	return '  '*level

# format and echo a label for given path, filename, size of disk usage, and
# indentation level
def label((path, filename, diskuse), level):
	if filename == '':
		tableh(path, level+2)
	else:
		ns = ':'.join(path.split(':')[1:]+[''])
		link = '<a href="{0}">{1}</a>'
		href = _baseurl + ns + filename
		label = filename
		if diskuse == 0:
			diskuse = 10
		element = '<font size="{0}pt">{1}</font>'.format(log(diskuse)-1, link.format(href, label))
		print '<span>{0}</span>'.format(filename)
		print indent(level+2)+element


# http://stackoverflow.com/questions/9725836/css-keep-table-cell-from-expanding-and-truncate-long-text
# http://stackoverflow.com/questions/2736021/super-simple-css-tooltip-in-a-table-why-is-it-not-displaying-and-can-i-make-it
# Construct a table optimized for horizontal alignment, that is, the table
# is expected to be wider than it is high.
# assuming that it is like this, cells are positioned in one column containing
# the lists head next to a second column representing the rest, recursively
def tableh(dirname, level):
	items = largest(dirname)
	if len(items) < 1:
		return
	path, filename, size = items.pop(0)
	print indent(level)+'<table width="100%" height="100%" class="tooltip" dir="{0}">'.format(['RTL', 'LTR'][level%2])
	namespaces = dirname.split(':')
	if len(namespaces) > 1 and level > 0:
		print indent(level+1)+'<span><a href="{1}">{0}</a></span>'.format(namespaces[-1],
			'map.py?id='+':'.join(namespaces[1:]))
	full = size
	# loop through items / tr/td
	# each tr contains two td
	level += 1
	remainder_h = 100.
	remainder_v = 100.

	while len(items)>0:
		rowspan = int(round(len(items)/2.))
		path, filename, size = items.pop(0)
		print indent(level)+'<tr>'

		# first td
		covering = size * remainder_h / full
		remainder_h -= covering
		full -= size
		print indent(level+1)+'<td class="tooltip" rowspan="{0}" width="{1}%" height="{2}%">'.format(rowspan, covering, remainder_v)
		label((path, filename, size), level)
		print indent(level+1)+'</td>'

		# second td
		if len(items) > 0:
			colspan = int(round(len(items)/2.))
			path, filename, size = items.pop(0)
			covering = size * remainder_v / full
			remainder_v -= covering
			full -= size
			print indent(level+1)+'<td class="tooltip" colspan="{0}" width="{2}%" height="{1}%">'.format(colspan, covering, remainder_h)
			label((path, filename, size), level)
			print indent(level+1)+'</td>'

		print indent(level)+'</tr>'
	level -= 1 # unindent
	print indent(level)+'</table>'


def compute(dirname):
	_names = resources(dirname)
	partition(dirname)


fields = cgi.FieldStorage()
try:
	root = fields['id'].value
	namespaces = root.split(':')
	if len(namespaces) > 2:
		if namespaces[0] == '':
			namespaces.pop(0)
except:
	root = ''
	namespaces=[]

path = os.sep.join(namespaces)
_names = resources(os.path.join(_documentroot, path))

print '''Content-Type: text/html

<!doctype html>
<head>
	<style type="text/css">
		td {
			border: 1px solid;
			background-color: white;
			text-align:center;
			font-family: 'Arial', 'sans serif';
			color: #A33;
			display: table-cell;
			white-space: nowrap;
			word-wrap: break-word;
			text-overflow: ellipsis;
			overflow:hidden;
		}
		a {
			color: #3A3;
			text-decoration: none;
		}
		a:visited, a:hover {
			color: #171;
		}
		td:hover {
			background-color: #F0FFE0;
		}
		table {
			background-color: white;
			padding: 0px;
			margin:0px;
			table-layout: fixed;
			cellspacing: 5px;
		}
		table:hover {
			background-color: #F0E0FF;
		}
		table.namespace {
			background-color: #99D;
		}
		table.namespace:hover {
			background-color: #C0C0FF;
		}
		.tooltip > span, 
		.tooltip > span > a {
			display: none;
		}
		.tooltip:hover > span,
		.tooltip:hover > span > a {
			display: block;
			position: absolute;
			font-size: 7pt;
			background-color: #FFF;
			border: 1px solid #CCC;
			margin: 20px 10px;
		}
		.tooltip:hover > span a {
			text-decoration: none;
			color: #33A;
		}
	</style>
</head>
<body>
<div width="100%" height="600" align="center">'''
#print '<h3>Namespace {0} ({1})</h4>'.format(root, path)
print '''<table width="800" height="600">
<tr><td>'''
tableh(':'+root, 0)
print '''</td></tr></table>
</div>
</body>'''




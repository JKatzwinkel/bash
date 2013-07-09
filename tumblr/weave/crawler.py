from urllib2 import openurl
from urllib import urlretrieve
from bs4 import BeautifulSoup
from urlparse import urlparse, urlsplit, urljoin


# extract stuff from page obtained by urllib2.urlopen
def extract(page):

	mimetype = page.info().gettype()
	if mimetype != 'text/html':
		logging.warning(' abort parsing due to unknown mimetype: %s' % mimetype)
		return []

	soup = BeautifulSoup(page)
	currenturl = page.geturl()
	#text = soup.get_text("|", strip=True)
	#content = soup.prettify()
	#data().add(currenturl, text, content)
	links = []

	for link in soup.find_all('a'):
		href = link.get('href')
		# are we able to open this?
		if href:
			refparts = urlsplit(href)
			if not refparts.scheme:
				if not refparts.netloc:
					href = urljoin(currenturl, ''.join(refparts[2:4]))
					links.append(href)
					data().add(href, link.get_text())
			elif refparts.scheme == 'http':
				links.append(href)
				data().add(href, link.get_text())


req = urllib2.Request(urlname, headers={
	'User Agent':'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:16.0) Gecko/20100101 Firefox/16.0',
	'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
	'Accept-Language': 'en-US,en;q=0.5',
	'Accept-Encoding': 'gzip, deflate',
	'Connection': 'keep-alive',
	'DNT': '1',
	'If-Modified-Since': 'Sat, 20 Oct 2012 01:43:23 GMT',
	'Cache-Control': 'max-age=0'
	})

page = openurl(req)

#bilder:
# http://stackoverflow.com/questions/3042757/downloading-a-picture-via-urllib-and-python
urlretrieve(url, filename)

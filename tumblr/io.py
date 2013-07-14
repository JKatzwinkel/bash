try:
    import xml.etree.cElementTree as ET
except ImportError:
    import xml.etree.ElementTree as ET


def loadXML(filename):
	for event, elem in ET.iterparse(filename):
		if event == 'start':
			print elem.tag
	return images

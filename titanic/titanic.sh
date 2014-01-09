#!/bin/bash

url=$(wget http://www.titanic-magazin.de/ich.war.bei.der.waffen.rss -q -O - \
	| grep -A 4 "<title>Gärtners kritisches Sonntags" \
	| sed -n 's/\s*<link>\([^<]*\)<.*/\1/gp')
echo $url

echo """
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!DOCTYPE html
     PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
     \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html xml:lang=\"en\" lang=\"en\" xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
	<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
</head>
<body>
	<div>""" > out.html

wget $url -q -O - \
	| sed -n 's/.*\(Gärtners kritisches Sonntagsfrühstück\):\([^<]*\)<\/div.*/<h3>\1<\/h3><h2>\2<\/h2>/p
	/<div class=.tt_news-bodytext/,/<\/div>/ { 
		/<p class/,/^\s*$/ {p}
	}' \
	| sed 's/<img[^>]*>//g' >> out.html

echo "</body></html>" >> out.html

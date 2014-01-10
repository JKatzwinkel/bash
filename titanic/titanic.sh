#!/bin/bash

url=$(wget http://www.titanic-magazin.de/ich.war.bei.der.waffen.rss -q -O - \
	| grep -A 4 "<title>Gärtners kritisches Sonntags" \
	| sed -n 's/\s*<link>\([^<]*\)<.*/\1/gp')

if [ -n "$(grep $url urls.txt)" ]; then
	exit
fi

echo $url >> urls.txt

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
	<div style=\"font-size:5px\">""" > out.html

wget $url -q -O - \
	| sed -n 's/.*\(Gärtners kritisches Sonntagsfrühstück\):\([^<]*\)<\/div.*/<b>\1<\/b><h4>\2<\/h4>/p
	/<div class=.tt_news-bodytext/,/<\/div>/ { 
		/<p class/,/^\s*$/ {p}
	}' \
	| sed 's/<img[^>]*>//g' \
	| sed 's/ä/\&auml;/g' \
	| sed 's/Ä/\&Auml;/g' \
	| sed 's/ö/\&ouml;/g' \
	| sed 's/Ö/\&Ouml;/g' \
	| sed 's/ü/\&uuml;/g' \
	| sed 's/Ü/\&Uuml;/g' \
	| sed 's/ß/\&szlig;/g' >> out.html

echo "</body></html>" >> out.html

#html2ps -o out.ps -e UTF-8 out.html 
#html2ps -o out.ps out.html 
htmldoc -t pdf -f out.pdf --webpage out.html

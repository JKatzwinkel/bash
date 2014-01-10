#!/bin/bash

url=$(wget http://www.titanic-magazin.de/ich.war.bei.der.waffen.rss -q -O - \
	| grep -A 4 "<title>Gärtners kritisches Sonntags" \
	| sed -n 's/\s*<link>\([^<]*\)<.*/\1/gp')

if [ ! -f urls.txt ]; then
	touch urls.txt
fi
if [ -n "$(grep $url urls.txt)" ]; then
	exit
fi

today=$(date +%y%m%d)
outfile="gksf$today"

echo "$today $url" >> urls.txt

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
	<div style=\"font-size:5px\">""" > "$outfile.html"

wget $url -q -O - \
	| sed -n 's/.*class=.tt_news-date.*\(05.01.2014\).*/\1: /p
	s/.*\(Gärtners kritisches Sonntagsfrühstück\):\([^<]*\)<\/div.*/<b>\1<\/b><h4>\2<\/h4>/p
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
	| sed 's/„/\&raquo;/g' \
	| sed 's/“/\&laquo;/g' \
	| sed 's/é/\&eacute;/g' \
	| sed 's/è/\&egrave;/g' \
	| sed 's/ß/\&szlig;/g' >> "$outfile.html"

echo "</body></html>" >> "$outfile.html"

#html2ps -o out.ps -e UTF-8 out.html 
#html2ps -o out.ps out.html 
htmldoc -t pdf -f "$outfile.pdf" --webpage "$outfile.html"

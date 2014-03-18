#!/bin/bash

# checkout latest whatif posting
wget http://whatif.xkcd.com -q -O - \
	| sed -n '/\s*<article class=.entry.>/,/\s*<\/article>/p' \
	> out.html
# extract resource identifier
url=$(grep "\s*<a href.*><h1>" out.html | grep -o "what-if\.xkcd\.com\/[0-9]*\/")
#echo $url

if [ -z "$url" ]; then
	#echo "no link found"
	exit
fi
# check if url is known already
dir="$HOME/.titanic"
if [ ! -d "$dir" ]; then
	mkdir -p $dir
fi
urlfile="$dir/urls.txt"
if [ ! -e "$urlfile" ]; then
	#echo "create file urls.txt"
	touch $urlfile
fi
if [ -n "$(grep $url $urlfile)" ]; then
	echo "no new entries. .."
	#exit
fi

# fix image location paths
sed -i 's/\(<img .*\)title=.\(.*\). src=.\([^ ]*\).>/\1src=\"http:\/\/whatif.xkcd.com\3\">\n<p class=\"illustration\">\2<\/p>/g' out.html

fnx="<span class=\"ref\"><span class=\"refnum\">"
echo "<p class=\"footnotes\">" > footnotes.html

# extract hyperlink locators
sed -i 's/\(<a href=.[^ ]*.>\)/\n\1/g' out.html
indices=(a b c d e f g h i j k l m n o p)
i=0
while read line; do
  echo $line | sed "s/\(.*\)\(<a href=..*.>.*<\/a>\)\(.*\)/\1\2<span class=\"refnum\">${indices[$i]}<\/span>\3/g"
  if [ -n "$(echo $line | grep '^<a href')" ]; then
    echo "<b>${indices[$i]}</b>" $(echo $line | sed -n "s/.*<a href=\"\([^ ]*\)\">.*<\/a>.*/\1/p") "<br>" >> footnotes.html
    i=$(( i+1 ))
  fi
done < <(cat out.html) > tmp.html
cp tmp.html out.html

sed -i 's/\(<span class=.ref.><span class=.refnum.>\)/\n\1/g' out.html
# footnotes
ix="0-9"
sed -n "s/.*$fnx\[\([$ix]*\)\]<\/span><span class=.refbody.>\(.*\)\($\|<\/span><\/span>\).*/<b>\1<\/b> \2<br>/p" out.html >> footnotes.html
sed -i "s/\($fnx\)\[\([$ix]*\)\]\(<\/span>\)<span class=.refbody.>\(.*\)\($\|<\/span><\/span>.*\)/\1\2\3\5/" out.html
# extract hyperlink footnotes
echo "</p>" >> footnotes.html

cat footnotes.html >> out.html


today=$(date +%y%m%d)
outfile="$dir/whatif$today"
echo "saving to $outfile.{html,pdf}"

echo "$today $url" >> $urlfile

echo """
<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!DOCTYPE html
     PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
     \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
<html xml:lang=\"en\" lang=\"en\" xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
  <style>
.refnum {
    position: relative;
    left: -1px;
    bottom: 1ex;
    font-family: Times, serif;
    font-size: .8em;
    font-weight: bold;
    cursor: pointer;}
#question {
    padding-top: 1.5em;
		margin:4em;}
#attribute {
    padding-bottom: 1.5em;
    text-align: right;
    margin-right: 20%;
    margin-top: -.7em;
    font-family: Verdana, Helvetica, Arial, sans-serif;}
.illustration {
  font-size: .9em;
  font-family: Times, serif;
  text-align: center;
  display: block;
  max-width: 100%;
  margin: 0 auto;
  padding: 0.7em 0;}
.footnotes {
	font-family: Times, serif;
	margin: 3em;
	max-width: 80%;
}
</style>
</head>
<body>
<div style=\"font-size:6px\">""" > "$outfile.html"

cat out.html >> "$outfile.html"

echo "</body></html>" >> "$outfile.html"

#html2ps -o out.ps -e UTF-8 out.html 
#html2ps -o out.ps out.html 
htmldoc -t pdf -f "$outfile.pdf" --size a4 --textfont times --webpage "$outfile.html"
lpr "$outfile.pdf"


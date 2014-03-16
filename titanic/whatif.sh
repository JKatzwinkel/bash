#!/bin/bash

# checkout latest whatif posting
wget http://whatif.xkcd.com -q -O - \
| sed -n '/\s*<article class=.entry.>/,/\s*<\/article>/p' \
> out.html
# extract resource identifier
url=$(grep "\s*<a href.*><h1>" out.html | grep -o "what-if\.xkcd\.com\/[0-9]*\/")
echo $url

# extract footnotes

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

./xkcd.sh

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
    left: -2px;
    bottom: 1ex;
    font-family: Verdana, sans-serif;
    font-size: .8em;
    font-weight: bold;
    cursor: pointer;}
#question {
    padding-top: 1.5em;}
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
</style>
</head>
<body>
<div style=\"font-size:6px\">""" > "$outfile.html"

cat out.html >> "$outfile.html"

echo "</body></html>" >> "$outfile.html"

#html2ps -o out.ps -e UTF-8 out.html 
#html2ps -o out.ps out.html 
#htmldoc -t pdf -f "$outfile.pdf" --size a4 --textfont times --webpage "$outfile.html"
#lpr "$outfile.pdf"


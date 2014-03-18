
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

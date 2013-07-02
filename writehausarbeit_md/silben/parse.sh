#/bin/bash

silbcode=
prerex=
sufrex=
v='[aeiouöäüy]'
c='[bcdfghjklmnprstvwxzß]'
l="[aeiouöäübcdfghjklmnprstvwxyzß]"
V="ai\|au\|ei\|eu\|ie\|oi\|ui\|äu"
#silb="\w\w*\($V\)\w*\|\w*\($V\)\w*\w\|\w\w*$v\w*\|\w*$v\w*\w"
silb="\($c$c*\($V\|$v\)$c*\|$c*\($V\|$v\)$c$c*\|$c*\($V\)$c*\)"
de="[\ .,:-]\|^\|$" #\b

trenn="\\\\-"

# combinations a sillable must not begin with
preill="\(h$c\|n$c\|r$c\|l$c\|sh\|x$c\|l$c\|chn\\|ck\|ss\|tt\|tz$c\|tg\|tl\|m$c\)"

rm prerex
rm sufrex

# written rules
rules=
# prefixes
while read e; do rules="${rules}s/\b\($e\)$silb/\1${trenn}\2/i; " ; done < $1
# suffixes
while read e; do rules="${rules}s/$silb\($e\)\b/\1${trenn}\5/i; " ; done < $2 # silb takes 4 groups

# generic
#silbcode="${silbcode}s/\($de\)\($c$v$c$c\)\($silb\)/\1\2${trenn}\3/gi; "
#silbcode="${silbcode}s/\($de\)\($v$v$c\)\($silb\)/\1\2${trenn}\3/gi; "
#prerex="${prerex}s/\b\($c$v$c\)$silb/\1${trenn}\2/gi; "
echo "${prerex}s/\b\($V\)$silb/\1${trenn}\2/i; " >> prerex
echo "${prerex}s/\b\($c$v\)$silb/\1${trenn}\2/i; " >> prerex
echo "${prerex}s/\b\($v$c\)$silb/\1${trenn}\2/i; " >> prerex
#prerex="${prerex}s/\b$silb$silb/\1${trenn}\4/i; "
#prerex="${prerex}s/\b$silb$silb/\1${trenn}\4/i; "


echo "${sufrex}s/$silb\($c$v\)\b/\1${trenn}\5/i; " >> sufrex
echo "${sufrex}s/$silb\($c$v$c\)\b/\1${trenn}\5/i; " >> sufrex
echo "${sufrex}s/$silb\(${c}iert\)\b/\1${trenn}\5/i; " >> sufrex
#sufrex="${sufrex}s/$silb\(${c}e\)\b/\1${trenn}\4/i; "

#silbcode="/^>/ !{/\b$silb$silb$\b/ { /\b$silb\b/ !{$silbcode}}}"
#silbcode="/^>/ !{/\b$silb\b/ !{ $prerex }}"
for rex in $(cat prerex); do prerex="$prerex /\b$silb$preill/I !{$rex}; "; done
for rex in $(cat sufrex); do sufrex="$sufrex $rex; "; done

#silbcode="/^>/ !{/\b$silb\b/I !{ /\b$silb$preill/I !{$prerex}; $sufrex; }}"
silbcode="/^[[>]/ !{/\b$silb\b/I !{ $rules; $prerex; $sufrex; }}"

#debugging
echo "$prerex"
echo "$sufrex"
grep -o "\b$silb\b" $3 > einsilbiges.txt

# do the action
# jedes wort in eigene zeile, newlines werden markiert
sed 's/$/\n>EOL/g; /\*/ !{s/ /\n/g}' $3 > sllb.tmp
#debug
sed -n "s/\b$silb$preill\(.*$\)/\1-\5\6/pig" sllb.tmp > illegales.txt

#sed -i 's/ /\n/g'
# trennungsregeln anwenden (nicht auf zeilen die nur eine silbe enthalten)
for i in 1 2; do
	sed -i "$silbcode" sllb.tmp
done

# zeilen wieder zusammenfuegen
for i in 1 2 3 4 5; do
	sed -in '/^>EOL$/ !{N; /EOL$/ !{s/\n/ /g;}; }' sllb.tmp
done
sed -in '/^EOL$/ !{ N; s/\n//g; s/>EOL$//g }' sllb.tmp

mv sllb.tmp $3

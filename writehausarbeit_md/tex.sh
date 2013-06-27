#!/bin/bash
#cat output.txt | sed -n '/^abstract\s>/,/^\s*$/{s/^abstract\s>/\\begin\{abstract\}/p;};/^[^\]/,/^\s*$/{s/^\s*$/\\end\{abstract\}/p}'

#cat output.txt | sed -n '/^abstract\s>/,/^\s*$/{/^[^\]*/,/^\s*$/{
# {s/^\s*$/\\end\{abstract\}/p;
#s/^abstract\s>//p;}}}'


odt2txt nlp.odt > output.tex

# umlaute
sed -i 's/ae/ä/g
        s/Ae/Ä/g
        s/oe/ö/g
        s/Oe/Ö/g
        s/Ue/Ü/g
        s/\([^q]\)ue/\1ü/g
        s/sz/ß/g' output.tex


# silbentrennung
bash silben/parse.sh "silben/prefixes" "silben/endungen" "output.tex"
cat output.tex
#exit 0

for ref in $(cat bibliography.bib | 
	grep -o "^@.*[^\}],$" | 
	sed  's/.*{\([^,} ]*\), *$/\1/g'); do
		sed -i "s,\[$ref\],\\\cite{$ref},g" "output.tex"
done


function onelinesimple(){
 sed -in '
 /'$1'..*'$1'/{
  s/'$1'/'$2'/;{1g}
  s/'$1'/'$3'/;{1g}
 }' output.tex
}

function multisimple() {
 sed -in '
  /'$1'/,/\('$1'\|^\s*$\)/ {
    s/'$1'/'$2'/g;n;
    s/'$1'/'$3'/g;n;
    s/'$1'/'$3'/g;n;
    s/'$1'/'$3'/g;n;
  }' output.tex
}

function oneline(){
 sed -in '
 /'$1'.*'$3'/{
  s/'$1'/'$2'/g
  s/'$3'/'$4'/g
 }' output.tex
}

function multiline(){
 sed -in '
 /'$1'/,/'$3'/{
   /'$3'/ !{
     s/'$1'/'$2'/;{1n}
    }
   s/'$3'/'$4'/
  }' output.tex
}



cr='\}'
bl='\['
# abstract, blockquotes
multiline '^>abstract\s*>\s*' '\\begin\{abstract\}' '^\s*$' '\\end\{abstract\}'
multiline '^>\s*' '\\begin\{quote\}' '^\s*$' '\\end\{quote\}'
# citations
oneline '\[' '\\cite\{' '\]' '\}'
# footnotes
multiline $bl '\\footnote\{' '\]' $cr
# italic
onelinesimple '\*' '\\textit\{' $cr
multisimple '\*' '\\textit\{' $cr
# bold
onelinesimple '\*\*' '\\textbf\{' $cr
multisimple '\*\*' '\\textbf\{' $cr
# capitalize dingens
onelinesimple '\^' '\\textsc\{' $cr
multisimple '\^' '\\textsc\{' $cr


# comments, quotation marks
sed -i 's/\(..*\)%/\1\\%/g;
        s/\s\"\(\w\)/ \"\`\1/g;
        s/\(\w\)\"\s/\1\"'\'' /g;
        s/&/\\&/g;' output.tex

# structure
sed -i 's/^\(.*\)# \(.*\)$/\\\1section\{\2\}/g;
        s/#/sub/g' output.tex

# silbentrennung
#v='[aeiouöäü]'
#c='[bcdfghjklmnprstvwxyzß]'
#for i in 1 2 3; do
#sed -i 's/\(\w\{2,\}'$c$v$v'\)\('$c$v$c'\s\)/\1\\-\2/gi
#        s/\(\s'$v$c'\)\('$c$v$c'\w*\)/\1\\-\2/gi
#        s/\('$c$v$v'\)\('$c$v$c'\)/\1\\-\2/gi
#        s/\(\s'$c$v$c'\)\('$c$v$c$c'\w*\)/\1\\-\2/gi
#        s/\(\s'$c$v$c'\)\('$c$v$c'\w*\)/\1\\-\2/gi
#        s/\(\s'$v$c$c'\)\('$c$v$c$c'\w*\)/\1\\-\2/gi
#        s/\(\s'$c$v'\)\('$c$v$c'\w*\)/\1\\-\2/gi
#        s/\(\s'$v$c'\)\('$c$c$v'\w*\)/\1\\-\2/gi
#        s/\(\s'$c$v$v$c'\)\('$c$v'\w\{2,\}\)/\1\\-\2/gi
#        s/\(\w*'$c$c$c$v'\)\('$c$v$c$c'\s\)/\1\\-\2/gi' output.tex
#done

head -n 50 ha.tex > tmp.tex
cat output.tex >> tmp.tex
tail -5 ha.tex >> tmp.tex

mv tmp.tex ha.tex

pdflatex ha.tex
bibtex ha.aux
pdflatex ha.tex
pdflatex ha.tex
evince ha.pdf &



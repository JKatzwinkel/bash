
#!/bin/bash

retumb="[[:alnum:]_\-]*\.tumblr\.com"

function print_manual () {
    echo "usage: fav [OPTIONS] BLOG[.tumblr.com] [BLOG2[.tumblr.com] ...]"
    echo ""
    echo "DESCRIPTION:"
    echo "    identifies the blogs that are recorded as a source for existent"
    echo "    images the most frequently. outputs a list of blogs" 
    echo "    which brought the most images found in the /img directory."
    echo "    for every given known tumblr blog, this script sets up"
    echo "    an initial search list readable by the crawler, "
    echo "    containing the most favorite blogs in descending order"
    echo "OPTIONS:"
    echo "    -l"
    echo "        evaluate only local source files. if this opton"
    echo "        is set, any global sources file is ignored"
    echo "    -t [FILE]"
    echo "        rather than putting together an initial list"
    echo "        in a given blog's tumbs file, output results"
    echo "........to the given destination (not implemented)"
    echo "    -n [NUM]"
    echo "        rather than limiting the result list to 50"
    echo "        by default, return at most NUM blogs (not"
    echo "        implemented)"
    echo "    -v"
    echo "        verbose output"
    echo "    -h"
    echo "        print this help"
}

function merge_lists () {
    mrg=""
    for l in $(echo -en "$1\n$2"); do
        for i in $( echo $l | grep -o "[^,]*\.tumblr\.com"); do
            if [ -z $(echo $mrg | grep -o $i) ]; then
                mrg="$mrg\n$i"
            fi
        done
    done
    echo -en "$mrg"
}

set -- $(getopt -- "-lvht:" $@)
while [ $# -gt 0 ]; do
    case $1 in 
        (-l) localsrc=true;;
        (-t) output=$2; shift;;
        (-n) resnumber=$2; shift;;
        (-h) print_manual; exit 0;;
        (-v) verbose=true;;
        (--) shift; break;;
        (*) blog=$( echo $1 | tr -d "\\/\'");
            if [ -z $(echo $blog | grep "\.tumblr\.com") ]; then
                dir="$blog"
                blog="$blog.tumblr.com"
            else
                dir=$(echo "$blog" | cut -d '.' -f 1)
                if [ ! -z $(echo "$dir" | grep "http://") ]; then
                    dir=$(echo "$dir" | cut -d '/' -f 2)
                fi
                    blog=$(echo $blog | grep -o "$retumb")
            fi;
            blogs="$blogs$blog,";;
    esac
    shift
done

echo "$blog" > $dir/tumbs
echo "" > $dir/fav

for i in $dir/img/*; do

	img=$(echo $i | cut -d '/' -f 3)
	ent=$(grep $img $dir/sources)
	src=$(echo $ent | cut -d ' ' -f 2 )
    if [ ! $localsrc ]; then
        srcglb=$(grep $img sources | cut -d ' ' -f 2)
    else 
        srcglb=""
    fi
	for s in $(merge_lists $src $srcglb); do
		#echo $s;
		ent=$(grep $s $dir/fav)
		if [ ! -z "$ent" ]; then
			cnt=$(echo $ent | cut -d ' ' -f 1 | grep -o "[1-9][0-9]*")
			fmt=$(printf "%3.3d" $(( cnt+1 )) )
			sed -i "s/^[0-9]* $s/$fmt $s/" $dir/fav
		else
			echo "001 $s" >> $dir/fav
		fi
	done
done




for tmb in $(cat $dir/fav | sort -r | head -50); do

    if [ $verbose ]; then
        if [ -z "$(echo $tmb | grep $retumb)" ]; then
            count="($(echo $tmb | grep -o "[1-9][0-9]*"))"
        else
            echo "$tmb $count"
        fi
    else 
	   echo $tmb | grep "$retumb"
    fi
	echo $tmb | grep "$retumb" >> $dir/tumbs

done

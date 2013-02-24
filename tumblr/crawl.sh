#!/bin/bash

retumb="[[:alnum:]_\-]*\.tumblr\.com"

sourcesglb=../sources
sourceslcl=sources
sourcesprm=$sourcesglb
double_entry=$sourceslcl
verbose=
dlnum=$(( 100 ))
formats="jpg,png,gif"

function print_manual () {
    echo "usage: tumblr [OPTIONS] BLOG[.tumblr.com] [BLOG2[.tumblr.com] ...]"
    echo ""
    echo "OPTIONS:"
    echo "    -g"
    echo "        keep track of image sources in a global sources file and a"
    echo "        local sources file"
    echo "        only download images that are not listed in the global sources"
    echo "        (default behaviour)"
    echo "    -l"
    echo "        keep track of image sources in a local sources file only"
    echo "        download all images unless already listed"
    echo "    -d"
    echo "    keep track of image sources both locally and globally"
    echo "        download all images not listed in the local sources file"
    echo "    -n [NUM]"
    echo "        limit number of images to download to NUM"
    echo "        default: 100"
    echo "    -e [FORMAT[,FORMAT]]"
    echo "        exclude given image formats from download consideration"
    echo "        default formats to download: jpg,png,gif"
    echo "    -v"
    echo "        verbose output"
    echo "    -h"
    echo "        print this help"
}

function save_reference() {
    if [ ! -z "$(grep -o "$1" "$3")" ]; then
        featured=$(grep "$1" "$3" | cut -d' ' -f2)
        if [ -z $(echo $featured | grep -o "$2") ]; then
            sed -i "s/$1 $retumb/&,$2/" "$3"
        fi
    else
        echo "$1 $2" >> "$3"
    fi
}



set -- $(getopt -- "-lgdvhn:e:" $@)
while [ $# -gt 0 ]; do
    case $1 in 
        (-g) sourcesprm=$sourcesglb; double_entry=$sourceslcl;;
        (-l) sourcesprm=$sourceslcl; double_entry="";;
        (-d) sourcesprm=$sourceslcl; double_entry=$sourcesglb;;
        (-n) dlnum=$(echo $2 | tr -d "'"); shift;;
        (-h) print_manual; exit 0;;
        (-e) ignored=( $(echo $2 | tr -d "'" | grep -o "[^,]*") );
			for format in ${ignored[@]}; do
				formats=$(echo $formats | sed "s/$format//")
			done;
			shift;;
        (-v) verbose=true;;
        (--) shift; break;;
        (*) blog=$( echo $1 | tr -d "\\/\'");
			blog=${blog#http:}
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


if [ -z "$blog" ] || [ -z "$dir" ]; then
    if [ ! -f "tumbs" ]; then
        print_manual
        exit
    else
        if [ ! -f "img"]; then
            mkdir "img"
        fi
        dir="."
        sourceslcl=../sources
        double_entry=""
    fi
fi

if [ $verbose ]; then
    echo "blogs: $blogs"
    echo "primary sources list: $sourcesprm"
    echo "secondary sources list: $double_entry"
    echo "work directory: $dir"
fi


if [ ! -f "$dir/img" ]; then
    mkdir -p "$dir/img"
fi
if [ ! -f "$dir/tumbs" ]; then
    touch "$dir/tumbs"
fi
if [ ! -f "$dir/$double_entry" ]; then
	touch "$dir/$double_entry"
    if [ $verbose ]; then
        echo "creating secondary source file $dir/$double_entry"
    fi
fi

for blog in $(echo $blogs | grep -o "$retumb"); do
    #blog=$(echo "$blog" | tr -d ",")
    if [ -z $(grep "$blog" "$dir/tumbs" | head -1) ]; then
        echo "$blog" >> "$dir/tumbs"
    fi
done




cd $dir


if [ ! -f "$sourcesprm" ]; then
    touch "$sourcesprm"
    if [ $verbose ]; then
        echo "creating primary source file $dir/$sourcesprm"
    fi
fi

ff=( $(echo $formats | grep -o "[^,]\+") )
freg="${ff[0]}"
for i in ${ff[@]:1}; do
	freg="$freg\|${i}"
done
formats="\($freg\)"

if [ $verbose ]; then
    echo "number of blogs listed to be visited: $(wc -l tumbs)"
    echo "image formats that will be downloaded: ${ff[@]} - $formats"
fi



# total download count
total=$(( 0 ))


line=$(( 1 ))

while [ $(( line )) -le $(wc -l 'tumbs' | cut -d' ' -f1 ) ]; do

    tumb=$( sed -n "${line}p" "tumbs")

    if [ -z $(echo $tumb | grep "\(www\|assets\|media\|staff\|static\)\.") ]; then

        echo -ne "$total+ $tumb"

        html=$(wget -q $tumb -O - )

        downloads=$(( 0 ))
        for img in $(echo $html | grep -io "img src=[\"\']http://[0-9]\{2\}\.media\.tumblr\.com/tumblr_\([0-9a-z_]*\)\.$formats" ); do
            url=$(echo $img | grep -io "http://[0-9]\{2\}\.media\.tumblr\.com/tumblr_\([0-9a-z_]*\)\.$formats" )
            name=$(echo $url | grep -io "tumblr_\([0-9a-z_\-]*\)\.$formats" )

            if [ ! -z $url ]; then
                if [ -z "$(grep "$name" "$sourcesprm")" ]; then
                    wget -q $url -O "img/$name"
                    downloads=$(( $downloads+1 ))
                    echo -ne "\r$total+ $tumb "
                    for i in $(seq 1 $downloads); do
                        echo -n "."
                    done
                    echo "$name $tumb" >> "$sourcesprm"
                else
                    featured=$(grep $name "$sourcesprm" | cut -d' ' -f2)
                    if [ $verbose ]; then
                        echo -en "\r $name known from "
                        echo -en "$(echo "$featured" | grep -o "$retumb" | head -1 | cut -d'.' -f1) "
                        tms=$(echo "$featured" | grep -o "$retumb" | wc -l)
                        if [ $tms -gt 1 ]; then
                            echo "and others (+$(( tms-1 )))"
                        else
                            echo ""
                        fi
                    else
                    	echo -n "_"
                    fi
                    if [ -z "$(echo $featured | grep $tumb | head -1)" ]; then
                        sed -i "s/$name $retumb/&,$tumb/" "$sourcesprm"
                    fi
                fi
                if [ ! -z $double_entry ]; then
                    save_reference $name $tumb $double_entry
                fi
            fi
        done


        echo -en "\r$total+ $tumb ($downloads)"
        for i in $(seq 1 $downloads); do
            echo -n " "
        done
        echo ""

        #TODO: make links lowercase
        for link in $(echo $html | grep -o "$retumb"); do
            if [ -z "$(grep -o "$link" "tumbs" | head -1)" ]; then
                echo $link >> "tumbs"
            fi
        done

        total=$(( total+downloads ))
        if [ $(( total )) -ge $(( dlnum )) ]; then
            echo "downloaded $total images"
            exit
        fi
    fi

    line=$(( $line+1 ))
done



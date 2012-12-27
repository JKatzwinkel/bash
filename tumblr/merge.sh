#!/bin/bash

retumb="[[:alnum:]_\-]*\.tumblr\.com"

function print_manual () {
    echo "usage: merge [OPTIONS] FILE1 FILE2"
    echo ""
    echo "DESCRIPTION:"
    echo "    merge the contents of tumblr source lists FILE1 and FILE2"
    echo "    outputs the resulting list into FILE2 unless specified otherwise"
    echo "OPTIONS:"
    echo "    -v"
    echo "        verbose output"
    echo "    -h"
    echo "        print this help and exit"
    echo "    -o"
    echo "        output into specified file"

}

function merge_files () {
    file1=$1
    file2=$2
    c=$(( 0 ))
    t=$( wc -l $file1 )
    while read line; do

        dat=( $(echo $line | grep -o "[^ ]*")  )
        img=${dat[0]}
        blogs=${dat[1]}

        line2=$(grep $img $file2)
        merge="$line2"

        if [ ! -z "$line2" ]; then
            for blog in $(echo $blogs | grep -o $retumb); do
                if [ -z $(echo $line2 | grep -o "$blog") ]; then
                    merge="$merge,$blog"
                fi
            done
        else
            merge=$line
        fi


        if [ ! -z "$line2" ]; then
            sed -i "s/$line2/$merge/" $file2
        else
            echo $merge >> $file2
        fi

        c=$(( c+1 ))
        printf "%3.3d" $c
        printf "/$t\r"

    done < $file1
    echo ""
}

set -- $(getopt -- "-vho:" $@)
while [ $# -gt 0 ]; do
    case $1 in
        (-h) print_manual; exit 0;;
        (-v) verbose=true;;
        (-o) output=$(echo $2 | tr -d "'"); shift;;
        (--) shift; break;;
        (*) if [ ! $file1 ]; then
                file1=$(echo $1 | tr -d "'")
            elif [ ! $file2 ]; then
                file2=$(echo $1 | tr -d "'")
            fi;;
    esac
    shift
done

if [ ! $output ]; then
    output=$file2
else
    if [ -f "$output" ]; then
        echo "cannot save to $output. file exists!"
        exit 1
    else
        touch $output
        if [ ! -f "$output" ]; then
            echo "error. could not access $output"
            exit 1
        fi
    fi
fi

if [ -d "$file1" ]; then
    file1="$(echo $file1 | grep -o ".*[^/]")/sources"
fi
if [ -d "$file2" ]; then
    file2="$(echo $file2 | grep -o ".*[^/]")/sources"
fi

if [ -f "$file1" ]; then
    if [ $verbose ]; then echo -ne "merge $file1 "; fi
    if [ -f "$file2" ]; then
        if [ $verbose ]; then
             if [[ "$output" == "$file2" ]]; then
                 echo "into $file2"
             else
                 echo "and $file2 into output file $output"
             fi
        fi
    else
        echo "cannot merge with $file2. file doesn't exist"
        exit 1
    fi
else
    echo "cannot merge $file1. file doesn't exist"
    exit 1
fi

if [ $verbose ]; then
    echo "total lines to merge: $(cat $file1 $file2 | wc -l)"
fi

if [[ "$output" == "$file2" ]]; then
    merge_files $file1 $file2
else
    cat $file2 > $output
    merge_files $file1 $output
fi

if [ $verbose ]; then
    echo "merge complete"
    echo "lines in result: $(wc -l $output)"
fi

#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Please specify directory to load music from"
	exit 1
elif [ ! -d "$1" ]; then
	echo "Invalid location $1: not a directory."
	exit 1
elif [ $# -gt 2 ]; then
	if [ -d "$2" ]; then
		cpdir=$2
		echo "Backup directory set to: $cpdir"
	else
		echo "Backup dir $2 invalid."
	fi
fi

dir=$1

cmus-remote -C "clear"
cmus-remote -C "add $dir"
cmus-remote -p

tmpfile=$(mktemp)

while true; do
	cmus-remote -n
	curfile=$(cmus-remote -C win-sel-cur 'echo {}')
	cmus-remote -Q > $tmpfile
	ta=$(sed -n 's/^tag artist \(.*\)$/\1/pg' $tmpfile)
	tt=$(sed -n 's/^tag title \(.*\)$/\1/pg' $tmpfile)
	echo $curfile
	echo "$ta - $tt"
	echo -n "What to do? [K]eep/[d]elete/[m]odify ID3 tags "
	read i
	if [ "$i" = "d" ]; then
		echo "removing $curfile"
		rm "$curfile"
	elif [ "$i" = "q" ]; then
		exit 0
	elif [ "$i" = "m" ]; then
		echo -n "Input ID3 tags like this: <Artist> - <Title>: "
		read tags
		ta=$(echo $tags | cut -d- -f 1)
		tt=$(echo $tags | cut -d- -f 2-)
		eyeD3 -a "$ta" -t "$tt" "$curfile"
	fi
done
	

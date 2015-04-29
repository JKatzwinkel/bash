#!/bin/bash

cpdir=
if [ $# -lt 1 ]; then
	echo "Please specify directory to load music from"
	exit 1
elif [ ! -d "$(realpath "$1")" ]; then
	echo "Invalid location $1: not a directory."
	exit 1
elif [ $# -gt 1 ]; then
	if [ -d "$(realpath "$2")" ]; then
		cpdir="$(realpath "$2")"
		echo "Backup directory set to: $cpdir"
	else
		echo "Backup dir $2 invalid."
	fi
fi

dir="$(realpath "$1")"

cmus-remote -C "clear"
cmus-remote -C "add $dir"
cmus-remote -p

tmpfile=$(mktemp)

#note: because it returns track currently under cursor,
# $(cmus-remote -C win-sel-cur 'echo {}') is not as reliable as 'file' field in cmus-remote -Q output

_filename () {
	cmus-remote -Q > $tmpfile # dump current song info query outputn
	field=$(grep "^file " "$tmpfile") # retrieve file name of current track
	echo ${field#file }
}

latest=
while true; do
	cmus-remote -C "view sorted"
	[ "$latest" = "$(_filename)" ] && cmus-remote -n
	curfile=$(_filename)
	ta=$(sed -n 's/^tag artist \(.*\)$/\1/pg' $tmpfile)
	tt=$(sed -n 's/^tag title \(.*\)$/\1/pg' $tmpfile)
	# do some fun to look at output stuff
	twid=$(( $(tput cols)-4 )) # terminal width
	mp3info="$ta - $tt" # echo some ID3 tags from current MP3
	fileinfo="$(basename "$curfile")"
	flocinfo="${curfile%${fileinfo}}"
	flocinfo="${flocinfo#${dir}}"
	# determine width of output bounding box:
	hdw=$(echo -en "70\n${#mp3info}\n${#fileinfo}\n${#flocinfo}" | sort -n | tail -1) # compute minimal width
	hdw=$(echo $(( $twid < $hdw ? $twid : $hdw ))) # compute max width (terminal width)
	# begin bounding box
	echo -n ┌ ;for j in $(seq $hdw); do echo -n "─"; done && echo ──┐
	echo "│ $mp3info"
	echo │ $fileinfo
	echo │ $flocinfo
	echo -n ├ && for j in $(seq $hdw); do echo -n "─"; done && echo ──┤
	echo -n "│ > What to do? [K]eep/[d]elete/[m]odify$([ -n "$cpdir" ]&&echo /[c]opy) > "
	read i
	if [ "$i" = "d" ]; then
		echo "│ > removing $(basename "$curfile")"
		rm "$curfile"
	elif [ "$i" = "q" ]; then
		exit 0
	elif [ "$i" = "m" ]; then
		echo -n "│ > Input ID3 tags like this: <Artist> - <Title>: "
		read tags
		ta=$(echo $tags | cut -d- -f 1)
		tt=$(echo $tags | cut -d- -f 2-)
		eyeD3 -l LEVEL:error -a "$ta" -t "$tt" "$curfile"
	elif [ "$i" = "c" ]; then
		if [ -n "$cpdir" ]; then
			echo "│ > Copying $(basename "$curfile")..."
			cp "$curfile" "$cpdir"
		fi
	fi
	echo -n └; for j in $(seq $hdw); do echo -n "─"; done && echo ──┘
	latest=$curfile
done
	

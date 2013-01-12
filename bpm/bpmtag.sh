#!/bin/bash

f=$1
if [ "$f" == "-f" ]; then
    force=true
    f=$2
fi

bpm=$( case ${f##*.} in
	'mp3')  mid3v2 -l "$f" ;;
	'ogg')  vorbiscomment -l "$f" ;;
	'flac') metaflac --export-tags-to=- "$f" ;;
esac )
bpm=$(echo $bpm | grep -o 'BPM=[[:digit:]]\+' | cut -d'=' -f2)
if [ ! $force ]; then
    if [ ! -z "$bpm" ]; then
        echo "${f##*/} already tagged: $bpm BpM"
        exit 0
    fi
fi

bpm=$(bpmcount "$f" 2>> /dev/stdout > /dev/null )
bpm=$(echo $bpm | grep '^[0-9^\.]*' | cut -d'.' -f1 )

echo "$f ($bpm BpM)"

case ${f##*.} in
    'mp3')  mid3v2 --TBPM "$bpm" "$f" ;;
	'ogg')  vorbiscomment -a -t "BPM=$bpm" "$f" ;;
	'flac') metaflac --set-tag="BPM=$bpm" "$f"
	        mid3v2 --TBPM "$bpm" "$f";;
esac

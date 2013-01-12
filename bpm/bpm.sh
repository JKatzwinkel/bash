#!/bin/bash

tmp=$($date | md5sum | cut -d' ' -f1)
find "$1" -iregex ".*\.\(mp3\|flac\|ogg\)" > $tmp

while read f; do
    bpm=$(bpmcount "$f" 2>> /dev/stdout > /dev/null )
    bpm=$(echo $bpm | grep '^[0-9^\.]*' | cut -d'.' -f1 )
    
    echo "$f ($bpm BpM)"
    
    case ${f##*.} in
        'mp3')  mid3v2 --TBPM "$bpm" "$f" ;;
		'ogg')  vorbiscomment -a -t "BPM=$bpm" "$f" ;;
		'flac') metaflac --set-tag="BPM=$bpm" "$f"
		        mid3v2 --TBPM "$bpm" "$f";;
    esac
done < $tmp

rm $tmp

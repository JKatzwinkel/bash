#!/bin/bash


hour=$(echo "$1" | cut -d ':' -f 1)
min=$(echo "$1" | cut -d ':' -f 2)
alarm_time=$(( hour*60+min ))

function minutes_left() {
 hour=$(date +%k)
 min=$(date +%M | grep "[1-9][0-9]\?")
 now=$(( hour*60+min ))
 left=$(( alarm_time-now ))
 if (( $left < 0 )); then
  left=$(( 1440-now + alarm_time ))
 fi
 echo $left
}

function progress_bar() {
 cols=$(tput cols)
 left=$1
 max=$2
 #len=$(echo $left)
 len=${#left}
 prog=$(( cols*(max-left)/max-len-3 ))
 bar=""
 for i in $(seq $prog); do
  bar="${bar}#"
 done
 bar="$bar[-$left]"
 echo $bar
}

left=$(minutes_left)
echo "$left Minutes ($(( left/60 )) hours) left."

if (( left < 100 )); then
 interval=$(( left*60/100 ))
else
 interval=$(( 70*60/100 ))
fi

steps=$(( 120 ))
inc=$(( 1 ))
echo "turndown interval: $interval"

listen=$(( steps*interval + steps * (steps+1) / 2 * inc ))
function toler() {
 left=$1
 dur=$(( left*60/3 ))
 if (( dur > 110*60 )); then
  dur=$(( 110*60 ))
 elif (( dur < 40 )); then
  dur=$(( 40 ))
 fi
 echo $dur
}



tolerable=$(toler $left)
echo -n "tolerated playback duration: $tolerable"

while (( tolerable < listen )); do
 if (( interval>1 )); then
  interval=$(( interval-1 ))
 else
  steps=$(( steps-1 ))
 fi
 listen=$(( steps*interval + steps * (steps+1) / 2 * inc ))
 #echo "durations: $listen $left $steps"
done

echo "; approximation: $listen seconds"
echo "playback volume turndown steps: $steps"
left=$(( left*60 ))
total=$left
#left=$(( left*60-interval*90 ))
for i in $(seq $steps); do
 #clementine -v $(( 90-(i*90/steps) ))
 clementine -v $(( 1+90*(steps-i)/steps * (steps/2+1) / (steps/2+i) ))
 #echo -en "turndown interval: $interval\r"
 #echo -en "time left: $left seconds       \r"
 echo -en "$(progress_bar $left $total)\r"
 sleep $(( interval ))
 left=$(( left-interval ))
 interval=$(( interval + inc ))
done

#left=$(minutes_left)
clementine -v 0

#echo "sleep ${left}m"
#sleep "${left}m"
while (( left>0 )); do
 sleep 1
 left=$(( left-1 ))
 #echo -en "time left: $left seconds       \r"
 echo -en "$(progress_bar $left $total)\r"
done

echo ""
date
echo -e "\nGood Morning!"
clementine --next
clementine --play

interval=$(( 70 ))
for i in $(seq 50); do
 clementine -v $(( 50+i ))
 sleep $interval
 interval=$(( interval-1 ))
done

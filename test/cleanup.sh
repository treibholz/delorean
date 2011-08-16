#!/bin/bash

echo "NOT YET WORKING"

case "$1" in

	create)
		for j in $(seq 1 24); do
			for i in $(seq 1 365); do
				mkdir -p /tmp/delorean/$(date -d "- $i days - $j hours" +%Y/%m/%d/%H-%M)
			done
		done
	;;
	*)
	;;
esac

cd /tmp/delorean/

find -maxdepth 4 | while read i; do

	if   DATE=$(date -d "${i:2:10} ${i:13:2}:${i:16:2}" +%s 2> /dev/null); then
		echo $DATE

	elif DATE=$(date -d "${i:2:10}" +%s 2>/dev/null); then
		echo $DATE
	elif DATE=$(date -d "${i:2:7}" +%s 2> /dev/null); then
		echo $DATE
	else
		echo $i
	fi
	


done

cd -

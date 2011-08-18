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

cd /tmp/delorean/ || exit 1

weekago=$(date -d '1 week ago' +%s)
monthago=$(date -d '1 month ago' +%s)
yearago=$(date -d '1 year ago' +%s)
now=$(date +%s)

# Timeperiods in seconds
DAY=$((60*60*24))
WEEK=$((DAY*7))
MONTH=$((DAY*30))
YEAR=$((DAY*365))


find -maxdepth 4 | while read i; do

#	TIMEFORMAT="+%Y%m%W%d%H%M"
	TIMEFORMAT="+%s"
	# DATE is the date encoded in the path of the backups converted to YYYYMMWWDDHHmm
	if   DATE=$(date -d "${i:2:10} ${i:13:2}:${i:16:2}" $TIMEFORMAT 2> /dev/null); then
		true
	elif DATE=$(date -d "${i:2:10}" $TIMEFORMAT 2>/dev/null); then
		#echo $DATE > /dev/null
		true

	elif DATE=$(date -d "${i:2:7}" $TIMEFORMAT 2> /dev/null); then
		#echo $DATE
		true

	else
		echo $i
	fi

	timediff=$((now - DATE))

	years_ago=$((timediff / YEAR))
	months_ago=$((timediff / MONTH))
	weeks_ago=$((timediff / WEEK))
	days_ago=$((timediff / DAY))

	echo $days_ago

	# delete if older than one year. Who really needs Backups that age?
	#if [ $DATE -lt $yearago ]; then
	#	echo $i
	# delete if older than one month if one os already spared
	#elif [ $DATE -lt $monthago ]; then
	#	true
	#fi 

done

cd -

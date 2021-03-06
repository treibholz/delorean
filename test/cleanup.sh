#!/bin/bash

export LANG=C

# Timeperiods in seconds
export DAY=$((60*60*24))
export WEEK=$((DAY*7))
export MONTH=$((DAY*30))
export YEAR=$((DAY*365))
now=$(date +%s)


function create_test_dirs () { # {{{
		for j in $(seq 1 5); do
			for i in $(seq 1 365); do
				Date=$(date -d "- $i days - $j hours" +%Y/%m/%d/%H-%M)
				mkdir -p /tmp/delorean/$Date
				touch /tmp/delorean/$Date/test.foo
			done
		done
} # }}}

function cleanup () { # {{{

	timediff=$((now - DATE))

	years_ago=$((timediff / YEAR))
	months_ago=$((timediff / MONTH))
	weeks_ago=$((timediff / WEEK))
	days_ago=$((timediff / DAY))

	if [ ${months_ago} -gt 2 ] ; then 
		if [ -z "${months[${months_ago}]}" ]; then
			months[${months_ago}]=${DATE}
		else
			echo "Cleaning ${i}"
			rm -rf "${i}"
		fi
	elif [ ${weeks_ago} -gt 4 ] ; then 
		if [ -z "${weeks[${weeks_ago}]}" ]; then
			weeks[${weeks_ago}]=${DATE}
		else
			echo "Cleaning ${i}"
			rm -rf "${i}"
		fi
	elif [ ${days_ago} -gt 7 ] ; then 
		if [ -z "${days[${days_ago}]}" ]; then
			days[${days_ago}]=${DATE}
		else
			echo "Cleaning ${i}"
			rm -rf "${i}"
		fi
	fi

} # }}}

function cleanup_run () { # {{{

	if [ "x${DEST_PATH}" == "x" ]; then
		echo "${DEST_PATH} not found"
		exit 2
	fi

	cd $DEST_PATH || exit 1

	find 2* -maxdepth 4 | while read i; do

		TIMEFORMAT="+%s"
		if DATE=$(date -d "${i:2:10} ${i:13:2}:${i:16:2}" $TIMEFORMAT 2> /dev/null); then
			export DATE
			cleanup
		elif DATE=$(date -d "${i:2:10}" $TIMEFORMAT 2>/dev/null); then
			if [ "x" = "x$(ls ${i})" ] ; then
				rm -rf ${i}
			fi

		elif DATE=$(date -d "${i:2:7}" $TIMEFORMAT 2> /dev/null); then
			if [ "x" = "x$(ls ${i})" ] ; then
				rm -rf ${i}
			fi

		else
			true
		fi
		
	done

	cd -

} # }}}


case "$1" in
	create)
		create_test_dirs
	;;
	clean)
		# run twice
		export DEST_PATH="${2}"
		cleanup_run
		cleanup_run
	;;
	all)
		$0 create
		$0 clean
	;;
	*)
		echo "RTFS!"
		exit 23
	;;
esac



#!/bin/bash
# Klaus Umbach <klaus-delorean@uxix.de>
# Licensed under the GPLv3

## Configuration

# default - may be overwritten in /etc/default/delorean
REMOTE_USER=delorean
HOST=backupserver
DEST_PATH=${HOSTNAME}
LOCK_FILE="/var/run/delorean.pid"
REMOTE_LOCK_FILE="/tmp/delorean.pid.${HOSTNAME}"
LAST_FILE="/var/lib/delorean.lastrun"
STATUS_FILE="/var/lib/delorean.status"

# only use real filesystems on real devices
PATHS=$(mount | grep '^/dev' | awk '{print $3}' | tr '\n' ' ')

EXCLUDE=""

## binaries

FLUXCAPACITOR="/usr/bin/ssh"
rsync="/usr/bin/rsync --delete -aHAXxv"
ionice="/usr/bin/ionice -c3"
date="/bin/date"

# Read external configuration, if available
test -e /etc/default/delorean && source /etc/default/delorean

export RSYNC_RSH="${FLUXCAPACITOR}"

# TODO: CLI-parameters

# Year/Month/Day
today="$($date +%Y)/$($date +%m)/$($date +%d)"

#if [ -e ${LAST_FILE} ] ; then
#	if [ "$(cat ${LAST_FILE})" == "${today}" ]; then
#		exit 0
#	fi
#fi

## Code

# minimal check if the host is there
host $HOST > /dev/null 2> /dev/null || exit 0

# These are the files, I find useless to backup on a desktop/notebook computer.
# I'm open to suggestions here!

SYS_EXCLUDE="/var/cache/apt/ tmp/ /var/run/ /var/lib/apt/lists/ /var/lib/clamav/ /var/lib/upower/ /var/lib/sudo/ /var/spool/exim4/ /var/log/ /var/mail/ $LAST_FILE /var/cache/openafs $LOCK_FILE mlocate.db var/cache/samba/ .xsession-errors etc/resolv.conf .*.swp etc/mtab var/lib/dhcp/ dev/"

ALL_EXCLUDE="$SYS_EXCLUDE $EXCLUDE"

# build the exclude-options
for i in $ALL_EXCLUDE; do
	exclude="$exclude --exclude=$i" 
done

# If we can use another user than root, we need to take care of the attributes
# and permissions via xattrs, so the destination filesystem needs to be mounted
# with "-o user_xattrs"

if [ "x${REMOTE_USER}" != "xroot" ] ; then
	fake_super="--rsync-path=/usr/bin/rsync --fake-super"
else
	fake_super=''
fi


# Assemble the local sync-command
rsync_opts="${exclude} ${fake_super}" 
sync_command="${ionice} ${rsync} ${rsync_opts} ${PATHS} ${REMOTE_USER}@${HOST}:${DEST_PATH}/trunk"


# Assemble the remote command to copy the data.
remote_command="( touch ${REMOTE_LOCK_FILE} && \
	cd ${DEST_PATH} && \
	mkdir -p ${today} && \
	${ionice} cp -al trunk ${today}/$(${date} +%H-%M) &&\
	rm ${REMOTE_LOCK_FILE} )"

# Lockfile checking
if [ -e ${LOCK_FILE} ]; then
	if [ -d /proc/$(cat ${LOCK_FILE}) ]; then
		if grep ${0} /proc/$(cat ${LOCK_FILE}) ; then
			echo "still running"
			echo "Lockfile: ${LOCK_FILE}"
			exit 0
		fi
	fi
else
	echo ${$} >  ${LOCK_FILE}

	# Now here happens the real backup.
	if (${sync_command})  ; then
		# Remote stuff to clean up 
		${FLUXCAPACITOR} ${REMOTE_USER}@${HOST} "${remote_command} > /dev/null & disown"
		logger -t $(basename ${0}) Backup finished
		echo "${today}" > ${LAST_FILE}
		rm -f ${LOCK_FILE}
	else
		rm ${LOCK_FILE}
		echo "ERROR..."
	fi
fi


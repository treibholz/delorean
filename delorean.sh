#!/bin/bash
# Klaus Umbach <klaus-delorean@uxix.de>
# Licensed under the GPLv3

## Configuration

# default - may be overwritten in /etc/default/delorean
REMOTE_USER=delorean
HOST=backupserver
DEST_PATH=${HOSTNAME}
LOCK_FILE="/var/run/delorean.pid"
LOG_FILE="/var/log/delorean.log"
REMOTE_LOCK_FILE="/tmp/delorean.lock.${HOSTNAME}"
LAST_FILE="/var/lib/delorean.lastrun"
STATUS_FILE="/var/lib/delorean.status"

# only use real filesystems on real devices
PATHS=$(mount | grep '^/dev' | awk '{print $3}' | tr '\n' ' ')

# Just predefined for user-defined excludes.
EXCLUDE=""

## binaries

FLUXCAPACITOR="/usr/bin/ssh"
rsync="/usr/bin/nice -n 19 /usr/bin/rsync --delete -aHAXxv"
ionice="/usr/bin/ionice -c3"
date="/bin/date"

# Read external configuration, if available
test -e /etc/default/delorean && source /etc/default/delorean

export RSYNC_RSH="${FLUXCAPACITOR}"

# TODO: CLI-parameters

# Year/Month/Day
today="$($date +%Y)/$($date +%m)/$($date +%d)"

## Code

# minimal check if the host is there
host $HOST > /dev/null 2> /dev/null || exit 0

# These are the files, I find useless to backup on a desktop/notebook computer.
# I'm open to suggestions here!

SYS_EXCLUDE="/var/cache/apt/ tmp/ /var/run/ /var/lib/apt/lists/ /var/lib/clamav/ /var/lib/upower/ /var/lib/sudo/ /var/spool/exim4/ /var/log/ /var/mail/ $LAST_FILE /var/cache/openafs $LOCK_FILE mlocate.db var/cache/samba/ .xsession-errors etc/resolv.conf .*.swp etc/mtab var/lib/dhcp/ dev/ var/cache/man/"

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
sync_command="${ionice} ${rsync} ${exclude} ${fake_super} ${PATHS} ${REMOTE_USER}@${HOST}:${DEST_PATH}/trunk"


# Assemble the remote command to set the hardlinks.
remote_command="( touch ${REMOTE_LOCK_FILE} && \
	cd ${DEST_PATH} && \
	mkdir -p ${today} && \
	${ionice} cp -al trunk ${today}/$(${date} +%H-%M) && \
	rm ${REMOTE_LOCK_FILE} \
)"


# local lockfile checking
if [ -e ${LOCK_FILE} ]; then
	if [ -d /proc/$(cat ${LOCK_FILE}) ]; then
		if grep ${0} /proc/$(cat ${LOCK_FILE}) ; then
			echo "still running" >> ${LOG_FILE}
			echo "Lockfile: ${LOCK_FILE}" >> ${LOG_FILE}
			exit 0
		fi
	fi
# and remote lockfile checking
elif ${FLUXCAPACITOR} ${REMOTE_USER}@${HOST} "test -e ${REMOTE_LOCK_FILE}"; then 
			echo "Sorry, still running on the remote side." >> ${LOG_FILE}
			exit 0
else
	echo ${$} >  ${LOCK_FILE}

	# Now here happens the real backup.
	if (${sync_command} >> ${LOG_FILE}) ; then

		# if the sync was successfull, we drop the command to set the hardlinks
		${FLUXCAPACITOR} ${REMOTE_USER}@${HOST} "${remote_command} > /dev/null & disown"

		# write it to syslog.
		echo "Backup finished" >> ${LOG_FILE}
		$date +%s > ${LAST_FILE}
		rm -f ${LOCK_FILE}
	else
		rm ${LOCK_FILE}
		echo "Something went wrong. Trying again next time." >> ${LOG_FILE}
	fi
fi


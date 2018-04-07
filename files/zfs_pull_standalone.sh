#!/bin/bash
#################################################
# This script pulls differential snapshots from 
# a remote zfs via ssh 
################################################
REMOTE="${1}"
REMOTE_FS="${2}"
LOCAL_FS="${3:-${2}}"

echo ${REMOTE} ${REMOTE_FS} ${LOCAL_FS}

zfs list "${LOCAL_FS}" 2> /dev/null > /dev/null
if [[ $? != 0 ]]
then
	NO_DATASET=1
	SEND_CMD="zfs send -RD"
else
	LOCAL_SNAP=$(zfs list -r -t snapshot "${LOCAL_FS}" | ( 
			while read name foo 
			do 
				echo ${name##*@}
			done
		) | grep -e "^zfs-pull-" | sort | tail -1)
	if [[ -z "${LOCAL_SNAP}" ]]
	then
		echo "houston we have a problem, no local snapshot available, local_fs was not pulled from remote"
		exit 1
	fi
	SEND_CMD="zfs send -R -I ${REMOTE_FS}@${LOCAL_SNAP}"
fi

echo $LOCAL_SNAP
REMOTE_SNAP=$(date "+zfs-pull-%Y-%m-%d-%H-%M-%S")

ssh "${REMOTE}" "zfs snap -r ${REMOTE_FS}@${REMOTE_SNAP} ; ${SEND_CMD} ${REMOTE_FS}@${REMOTE_SNAP} | pigz -9 -c -" | zfs receive "${LOCAL_FS}"


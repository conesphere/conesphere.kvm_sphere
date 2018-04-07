#!/bin/bash
#################################################
# This script pulls differential snapshots from 
# a remote zfs via ssh 
################################################
REMOTE="${1}"
REMOTE_FS="${2}"
LOCAL_FS="${3:-${2}}"

zfs list "${LOCAL_FS}" 2> /dev/null > /dev/null
if [[ $? == 0 ]]
then
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
else
	LOCAL_SNAP=""
fi

ssh "${REMOTE}" "zfs-pull-server.sh ${REMOTE_FS} ${LOCAL_SNAP}" | zfs receive "${LOCAL_FS}"


#!/bin/bash
#################################################
# This script pulls differential snapshots from 
# a remote zfs via ssh 
################################################
FS="${1}"
SNAP="${2}"

FS_ESCAPED=$(systemd-escape "${FS}")
if [[ ! -e "/etc/zfs-pull-exports/${FS_ESCAPED}" ]]
then
	if [[ ! -e "${HOME}/.zfs-pull-exports/${FS_ESCAPED}" ]]
	then
		echo Filesystem to send is not in pull exports
		exit 23
	fi
fi

NEW_SNAP=$(date "+zfs-pull-%Y-%m-%d-%H-%M-%S")

if [[ "${SNAP}" = zfs-pull-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]]
then
	SEND_CMD="zfs send -RD"
else
	SEND_CMD="zfs send -R -I ${FS}@${SNAP}"
fi

zfs snap -r ${FS}@${NEW_SNAP} ; ${SEND_CMD} ${FS}@${NEW_SNAP} 
# no compression makes debugging simpler 
# | pigz -9 -c -


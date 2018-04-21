#!/bin/bash
## ZYNK: The Zuper Zimple ZFS Sync (Replication) Tool
## Form: zynk local/dataset root@remote.host destination/dataset 

# Please note: The reason this is so simple is because there is no error checking, reporting, or cleanup.
#               In the event that something goes wonkey, you'll manually need to fix the snapshots and
# Furthermore, this absolutely relies on the GNU version of 'date' in order to get epoch time
# Before using, make sure you've distributed your SSH key to the remote host and can ssh without password.

if [ ! $2 ] 
then
        echo "Usage: zynk local/dataset root@remote.host destination/dataset"
        exit
fi


DATE=`/usr/gnu/bin/date +%s`
if [ $DATE == "%s" ]
then
        echo "Must use GNU Date, please install and modify script."
        exit
fi


SRC=$1
HOST=$2
DEST=$3
PORT=${DATE:6}

if [ ! $3 ]
then
DEST=${SRC}
fi


LOCAL_SNAP_TIME=`/usr/sbin/zfs list -t snapshot -o name -H | /usr/gnu/bin/grep -P -o2 "${SRC}@zynk-\K([0-9]+)" | sort -r | head -n 1`
REMOTE_SNAP_TIME=`ssh -i /home/admin/.ssh/id_rsa admin@${HOST} "/usr/sbin/zfs list -t snapshot -o name -H | /usr/gnu/bin/grep -P -o2 '${DEST}@zynk-\K([0-9]+)' | sort -r | head -n 1"`
OLD_DATE=${LOCAL_SNAP_TIME}

echo "Time: ${DATE} Port: ${PORT} Copy: ${SRC} -> ${HOST}:${DEST} (Snapshots: ${LOCAL_SNAP_TIME}/${REMOTE_SNAP_TIME})"

if [ ! -z ${LOCAL_SNAP_TIME} ] && [ ! -z ${REMOTE_SNAP_TIME} ] && [ ${LOCAL_SNAP_TIME} -eq ${REMOTE_SNAP_TIME} ]
then
        # Datafile is found, creating incr.
        echo "Incremental started at `date`"
        # Snapshot machen
        /usr/sbin/zfs snapshot -r ${SRC}@zynk-${DATE}
        # mbuffer remote zum empfangen starten
        ssh -i /home/admin/.ssh/id_rsa admin@${HOST} "mbuffer -s 128k -m 1G -I ${PORT} | pfexec /usr/sbin/zfs receive -F ${DEST}" &
        sleep 5
        # daten seit letztem snapshot per mbuffer senden
        /usr/sbin/zfs send -RI ${SRC}@zynk-${OLD_DATE} ${SRC}@zynk-${DATE} | mbuffer -s 128k -m 1G -O ${HOST}:${PORT}
        # letzten snapshot loeschen
        /usr/sbin/zfs destroy -r ${SRC}@zynk-${OLD_DATE}
        # auch remote loeschen
        ssh -i /home/admin/.ssh/id_rsa admin@${HOST} "pfexec /usr/sbin/zfs destroy -r ${DEST}@zynk-${OLD_DATE}"
        # Datum vom aktuellen Snapshot speichern 
        echo "Incremental complete at `date`"
else 
        # Datafile not found, creating full.
        echo "Full started at `date`"
        # Snapshot machen
        /usr/sbin/zfs snapshot -r ${SRC}@zynk-${DATE}
        # mbuffer remote zum empfangen starten
        ssh -i /home/admin/.ssh/id_rsa admin@${HOST} "mbuffer -s 128k -m 1G -I ${PORT} | pfexec /usr/sbin/zfs receive -F ${DEST}" &
        sleep 5
        # daten seit letztem snapshot per mbuffer senden
        /usr/sbin/zfs send -R ${SRC}@zynk-${DATE} | mbuffer -s 128k -m 1G -O ${HOST}:${PORT}
        # Datum vom aktuellen Snapshot speichern 
        echo "Full completed at `date`"
fi

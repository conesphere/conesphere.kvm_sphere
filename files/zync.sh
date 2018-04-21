#!/bin/bash
## ZYNK: The Zuper Zimple ZFS Sync (Replication) Tool
## Form: zynk local/dataset root@remote.host destination/dataset

# Please note: The reason this is so simple is because there is no error checking, reporting, or cleanup.
#               In the event that something goes wonkey, you'll manually need to fix the snapshots and
#               modify or remote the /var/run/zynk datafile which contains the most recent snapshot name.
# Furthermore, this absolutely relies on the GNU version of 'date' in order to get epoch time
# Before using, make sure you've distributed your SSH key to the remote host and can ssh without password.
# 
# Originally written by Ben Rockwood (cuddletech) and modified with recursion by Mathias Lüttgens and 
# Extended with missu

if [ ! $3 ] 
then
        echo "Usage: zynk local/dataset root@remote.host destination/dataset"
        echo "WARNING: The destination is the full path for the remote dataset, not the prefix dataset stub."
        exit
fi

DATE=`date +%s`
if [ $DATE == "%s" ]
then
        echo "Must use GNU Date, please install and modify script."
        exit
fi

if [ -e /var/run/zynk ] 
then
        # Datafile is found, creating incr.
        echo "Incremental started at `date`"
        zfs snapshot -r ${1}@zynk-${DATE}
        zfs send -RI  ${1}@zynk-`cat /var/run/zynk` ${1}@zynk-${DATE} | ssh ${2} zfs recv -Fd ${3}
        zfs destroy -r ${1}@zynk-`cat /var/run/zynk`
        ssh ${2} zfs destroy -r ${3}@zynk-`cat /var/run/zynk`
        echo ${DATE} > /var/run/zynk
        echo "Incremental complete at `date`"
else 
        # Datafile not found, creating full.
        echo "Full started at `date`"
        zfs snapshot -r ${1}@zynk-${DATE}
        zfs send -R     ${1}@zynk-${DATE} | ssh ${2} zfs recv -Fd ${3}
        echo ${DATE} > /var/run/zynk
        echo "Full completed at `date`"
fi

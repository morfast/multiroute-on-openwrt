#!/bin/sh

LOCKFILE=/tmp/go.sh.lock

set -x
while :
do
	ip route | grep -q weight
	if [ $? -ne 0 -a ! -f ${LOCKFILE} ]; then
		cd /root/multiroute
		./adjustroute.sh
	fi
	sleep 10
done

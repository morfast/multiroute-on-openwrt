#!/bin/sh

set -x
while :
do
	ip route | grep -q weight
	if [ $? -ne 0 ]; then
		cd /root/multiroute
		./adjustroute.sh
	fi
	sleep 10
done

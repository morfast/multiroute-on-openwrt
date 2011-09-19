#!/bin/sh

set -x
while :
do
	ip route | grep -q weight
	if [ $? -ne 0 ]; then
		NPPP=$(ip route |  grep 'pppoe.*link' | wc -l)
		cd /root/multiroute
		./adjustroute.sh
	fi
	sleep 20
done

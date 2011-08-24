#!/bin/sh

source /etc/profile

while :
do
	ip link | grep -q eth1
	if [ $? -eq 0 ]; then
		break
	fi
	sleep 1
done

for i in $(seq -w 01 $1)
do
    ifconfig | grep -q eth${i} && continue
    ip link add link eth1 eth${i} type macvlan
    ifconfig eth${i} hw ether 40:16:9F:36:B1:${i}
    ifconfig eth${i} up 
done

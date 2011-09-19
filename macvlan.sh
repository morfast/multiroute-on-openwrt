#!/bin/sh

# check to see if the wan interface is up
while :
do
	ip link | grep -q ${WAN_IF}
	if [ $? -eq 0 ]; then
		break
	fi
	sleep 1
done


# add macvlan interfaces, from eth01, eth02 ... to eth$1
for i in $(seq -w 01 $1)
do
    ifconfig | grep -q eth${i} && echo "eth${i} is up" && continue
    ip link add link ${WAN_IF} eth${i} type macvlan
    ifconfig eth${i} hw ether ${MAC_PREFIX}:${i}
    ifconfig eth${i} up 
    echo "eth${i} is up"
done

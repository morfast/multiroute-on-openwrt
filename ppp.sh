#!/bin/sh

#exit 0

source /etc/profile

PPP_SYNC_FILE="/tmp/ppp_sync"
PPP_NUM_FILE="/tmp/ppp_num"

if [ $# -eq 1 ]; then
	PPP_NUM=$1
else
	PPP_NUM=10
fi

echo ${PPP_NUM} connection will be accomplished

./macvlan.sh ${PPP_NUM} 

echo -n "Killing existing pppd ..."
pkill pppd && sleep 3
pkill -9 pppd && sleep 1
echo "Done"

:> /tmp/ppp_sync
echo -ne '\x00' > ${PPP_SYNC_FILE}
#echo $PPP_NUM > ${PPP_NUM_FILE}

./lockfile ${PPP_NUM} &

for i in $(seq -w 01 $PPP_NUM)
do
pppd plugin rp-pppoe.so mtu 1492 mru 1492 nic-eth${i} persist usepeerdns user "user" password "pass" ipparam wan ifname pppoe-wan${i} nodetach &

done

#/multiroute.sh ${PPP_NUM}

exit 0


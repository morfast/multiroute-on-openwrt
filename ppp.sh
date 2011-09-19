#!/bin/sh

#exit 0
#set -x

USER="18959217916"
PASS="726622"

./light.sh blink 400 &

source /etc/profile &> /dev/null

if [ $# -eq 1 ]; then
	PPP_NUM=$1
else
	PPP_NUM=5
fi

if [ ${PPP_NUM} -ge 1 ] && [ ${PPP_NUM} -le 30 ]; then
	echo ${PPP_NUM} connection will be accomplished
else
	echo "number out of range"
	exit 1
fi

./macvlan.sh ${PPP_NUM} 

echo -n "Killing existing pppd ..."
pkill pppd && sleep 4
pkill -9 pppd && sleep 1
pkill initppp && sleep 2
pkill -9 initppp && sleep 1
pkill pppd && sleep 2
echo "Done"


./initppp ${PPP_NUM} &

for i in $(seq -w 01 $PPP_NUM)
do
./pppd plugin /usr/lib/pppd/2.4.4/rp-pppoe.so mtu 1492 mru 1492 nic-eth${i} persist usepeerdns user ${USER} password ${PASS} ipparam wan ifname pppoe-wan${i} nodetach &
done

sleep 2
./multiroute.sh ${PPP_NUM}

set +x
exit 0


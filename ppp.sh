#!/bin/sh

#exit 0
#set -x

./light.sh blink 400 &
source /etc/profile &> /dev/null

# read in the config file
source ./config

if [ $# -eq 1 ]; then
	PPP_NUM=$1
fi

if [ ${PPP_NUM} -ge 1 ] && [ ${PPP_NUM} -le 30 ]; then
	echo ${PPP_NUM} connection will be accomplished
else
	echo "number of connections out of range"
	exit 1
fi

./macvlan.sh ${PPP_NUM} 

echo -n "Killing existing pppd ..."
pkill pppd && sleep 3
pkill -9 pppd && sleep 1
echo -n "Killing existing initppp ..."
pkill initppp && sleep 1
pkill -9 initppp && sleep 1
echo "Done"


./initppp ${PPP_NUM} &

for i in $(seq -w 01 $PPP_NUM)
do
echo -n "Establish connection ${i} ... "
./pppd plugin /usr/lib/pppd/2.4.4/rp-pppoe.so mtu 1492 mru 1492 nic-eth${i} persist \
usepeerdns user ${USERNAME} password ${PASSWORD} ipparam wan ifname ${PPP_IF_PREFIX}${i} nodetach &
echo "done"
done

./multiroute.sh ${PPP_NUM}

#set +x
exit 0


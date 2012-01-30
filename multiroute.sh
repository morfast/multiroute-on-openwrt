#!/bin/sh

#exit 0
#set -x

# read in the config file
source /etc/syncppp.conf

touch ${LOCKFILE}

light.sh blink 400 &
source /etc/profile &> /dev/null

if [ $# -eq 1 ]; then
	PPP_NUM=$1
fi

if [ ${PPP_NUM} -ge 1 ] && [ ${PPP_NUM} -le 30 ]; then
	echo "trying to establish ${PPP_NUM} connections ... "
else
	echo "number of connections out of range"
	exit 1
fi

macvlan.sh ${PPP_NUM} 

echo -n "Killing existing pppd ..."
pkill pppd && sleep 3
pkill -9 pppd && sleep 1
echo -n "Killing existing syncpppinit ..."
pkill syncpppinit && sleep 1
pkill -9 syncpppinit && sleep 1
echo "Done"


syncpppinit ${PPP_NUM} &

for i in $(seq -w 01 $PPP_NUM)
do
echo -n "executing pppd for connection ${i} ... "
pppd plugin /usr/lib/pppd/2.4.4/rp-pppoe.so mtu 1492 mru 1492 nic-eth${i} persist \
usepeerdns user ${USERNAME} password ${PASSWORD} ipparam wan ifname ${PPP_IF_PREFIX}${i} nodetach &
echo "done"
done

testlink.sh ${PPP_NUM}
adjustroute.sh ${PPP_NUM}

rm -f ${LOCKFILE}
#set +x
exit 0


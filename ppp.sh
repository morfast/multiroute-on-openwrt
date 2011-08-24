#!/bin/sh

#exit 0
#set -x

/root/light.sh blink &

source /etc/profile

if [ $# -eq 1 ]; then
	PPP_NUM=$1
else
	PPP_NUM=10
fi

echo ${PPP_NUM} connection will be accomplished

/root/macvlan.sh ${PPP_NUM} 

echo -n "Killing existing pppd ..."
pkill pppd && sleep 2
pkill -9 pppd && sleep 1
echo "Done"


/root/initppp ${PPP_NUM} &

for i in $(seq -w 01 $PPP_NUM)
do
/root/pppd plugin rp-pppoe.so mtu 1492 mru 1492 nic-eth${i} persist usepeerdns user 480071448@fzjslan password xi570706 ipparam wan ifname pppoe-wan${i} nodetach &
done

/root/multiroute.sh ${PPP_NUM}

set +x
exit 0


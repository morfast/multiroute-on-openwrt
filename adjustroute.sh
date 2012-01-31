#!/bin/sh

#set -x

source /etc/syncppp.conf

if [ $# -eq 1 ]; then
	PPP_NUM=$1
fi

SUCCESS_LINKS=$(ip route | grep "${PPP_IF_PREFIX}.*proto" | awk '{print $3}')
ROUTECMD="ip route replace default \\
          "
iptables -t nat -F
iptables -t mangle -F
iptables -t raw -F
iptables -F
  
iptables -P FORWARD ACCEPT

ip rule flush
ip rule add prio 32766 from all lookup main
ip rule add prio 32767 from all lookup default

for i in $(seq -w 01 ${PPP_NUM})
do
    echo $SUCCESS_LINKS | grep -q ${PPP_IF_PREFIX}${i}
    if [ $? -ne 0 ]; then
    	pkill -f ${PPP_IF_PREFIX}${i}
    	continue
    fi
    
    IP_PPP=$(ip route | grep ${PPP_IF_PREFIX}${i} | awk '{print $9}')

    echo "manipulating ${PPP_IF_PREFIX}${i} ..."
    echo -n "modify routing table ... "
    ip route flush table P${i}
    ip route add $(ip route show table main | grep "${PPP_IF_PREFIX}${i}.*src") table P${i}
    PPPGATE=$(ip route | grep "${PPP_IF_PREFIX}${i}.*src" | awk '{print $1}')
    ip route add default via ${PPPGATE} dev ${PPP_IF_PREFIX}${i} table P${i}
    echo "OK"

    echo -n "modify routing rule ..."
    ip rule add prio 20000 fwmark 0x${i} table P${i}
    ip rule add prio 30000 from ${IP_PPP} table P${i}
    echo "OK"

    ROUTECMD="${ROUTECMD}nexthop via ${PPPGATE} dev ${PPP_IF_PREFIX}${i}  weight 1 \\
              "
    echo -n "modify iptables rules ..."
    if [ $BALANCE_METHOD == 'random' ]; then
        iptables -t mangle -A POSTROUTING -o ${PPP_IF_PREFIX}${i}  -m state --state NEW -j CONNMARK --set-mark 0x${i}
    elif [ $BALANCE_METHOD == 'seq' ]; then
        iptables -t mangle -I PREROUTING -m state --state NEW -m statistic --mode nth --every ${PPP_NUM} --packet $((${i#0}-1)) \
        -j MARK --set-mark 0x${i}
    fi

    iptables -t nat -A POSTROUTING -o ${PPP_IF_PREFIX}${i} -j SNAT --to ${IP_PPP}
    echo "OK"

done

iptables -t mangle -I PREROUTING -i br-lan -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
if [ $BALANCE_METHOD == 'random' ]; then
    echo -1 > /proc/sys/net/ipv4/rt_cache_rebuild_count
    iptables -t mangle -I POSTROUTING -m state --state ESTABLISHED,RELATED -j ACCEPT
    echo "Adding default route ... "
    eval "${ROUTECMD}"
elif [ $BALANCE_METHOD == 'seq' ]; then
    iptables -t mangle -A POSTROUTING -m state --state NEW -j CONNMARK --save-mark
    echo "Adding default route ... "
    ip route replace default via ${IP_PPP}
fi
echo "ALL DONE"

ip route flush cache

pkill -f light.sh
light.sh on

echo 
echo "=================Connections information==========================="
ip route | grep ${PPP_IF_PREFIX}
echo "==================================================================="

#set +x

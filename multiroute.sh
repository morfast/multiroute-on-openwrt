#!/bin/ash

#!/bin/sh

source /etc/profile

if [ $# -eq 1 ]; then
	PPP_NUM=$1
else
	PPP_NUM=10
fi

echo ${PPP_NUM} connections to handle

echo -1 > /proc/sys/net/ipv4/rt_cache_rebuild_count

count=0
while :
do
    NLINE=$(ifconfig | grep pppoe | wc -l)
    if [ ${NLINE} -eq ${PPP_NUM} ]; then
        break
    fi  
    sleep 1
    count=$(( count + 1 ))
    if [ $count -gt 10 ]; then
    	if [ ${PPP_NUM} -le 1 ]; then
    	    pkill pppd
    	    pkill -9 pppd
    	    pkill -9 lockfile
    	    exit 1
    	else
    	    pkill lockfile
    	    sleep 1
    	    pkill -9 lockfile
    	    exec /root/ppp.sh $(( PPP_NUM - 3 ))
    	    exit 0
    	fi
    fi
done
                        

ROUTECMD="ip route add default \\
          "
          
iptables -t nat -F
iptables -F
  
iptables -P FORWARD ACCEPT

ip rule flush
ip rule add prio 32766 from all lookup main
ip rule add prio 32767 from all lookup default

for i in $(seq -w 01 ${PPP_NUM})
do

    IP_PPP=$(ip route | grep pppoe-wan${i} | awk '{print $9}')

    echo -n "modify routing table ... "
    ip route flush table P${i}
    ip route add $(ip route show table main | grep "pppoe-wan${i}.*src") table P${i}
    ip route add default via ${IP_PPP} table P${i}
    echo "OK"

    echo -n "modify routing rule ..."
    ip rule add prio 30000 from ${IP_PPP} table P${i}
    echo "OK"

    PPPGATE=$(ip route | grep "pppoe-wan${i}.*src" | awk '{print $1}')
    ROUTECMD="${ROUTECMD}nexthop via ${PPPGATE} dev pppoe-wan${i}  weight 1 \\
              "

    #iptables -A INPUT -i pppoe-wan${i} -j ACCEPT
    #iptables -A FORWARD -i pppoe-wan${i} -j ACCEPT

    iptables -t nat -A POSTROUTING -o pppoe-wan${i} -j SNAT --to ${IP_PPP}

done

#ip route del default
eval "${ROUTECMD}" && echo "DONE"


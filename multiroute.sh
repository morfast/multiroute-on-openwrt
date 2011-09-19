#!/bin/ash

#!/bin/sh

source /etc/profile
#set -x

if [ $# -eq 1 ]; then
	PPP_NUM=$1
else
	PPP_NUM=4
fi


echo -1 > /proc/sys/net/ipv4/rt_cache_rebuild_count

echo ${PPP_NUM} connections to handle
TIMEOUT=$(( PPP_NUM / 2 + 9))
echo timeout: ${TIMEOUT}
count=0
while :
do
    NLINE=$(ifconfig | grep pppoe | wc -l)
    if [ ${NLINE} -eq ${PPP_NUM} ]; then
        echo ${NLINE} connections established
    	SUCCESS_LINKS=$(ip route | grep 'pppoe.*pro' | awk '{print $3}')
        break
    fi  
    sleep 1
    count=$(( count + 1 ))
    if [ $count -gt ${TIMEOUT} ]; then
    	if [ ${NLINE} -le 0 ]; then
    	    echo "no connection established, exit"
    	    pkill pppd
    	    pkill -9 pppd
    	    pkill initppp
    	    pkill -f light.sh
    	    ./go.sh $((PPP_NUM-1))
    	    exit 1
    	fi
        NLINE=$(ifconfig | grep pppoe | wc -l)
        echo ${NLINE} connections established
    	SUCCESS_LINKS=$(ip route | grep 'pppoe.*pro' | awk '{print $3}')
    	pkill initppp
    	break
    	
    fi
done
#set +x
                        

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
    echo $SUCCESS_LINKS | grep -q wan${i}
    if [ $? -ne 0 ]; then
    	pkill -f pppoe-wan${i}
    	sleep 1
    	pkill -9 -f pppoe-wan${i}
    	continue
    fi
    
    IP_PPP=$(ip route | grep pppoe-wan${i} | awk '{print $9}')

    echo -n "modify routing table ... "
    ip route flush table P${i}
    ip route add $(ip route show table main | grep "pppoe-wan${i}.*src") table P${i}
    PPPGATE=$(ip route | grep "pppoe-wan${i}.*src" | awk '{print $1}')
    ip route add default via ${PPPGATE} dev pppoe-wan${i} table P${i}
    echo "OK"

    echo -n "modify routing rule ..."
    ip rule add prio 20000 fwmark ${i} table P${i}
   #ip rule add prio 30000 from ${IP_PPP} table P${i}
    echo "OK"

    ROUTECMD="${ROUTECMD}nexthop via ${PPPGATE} dev pppoe-wan${i}  weight 1 \\
              "
    #iptables -A INPUT -i pppoe-wan${i} -j ACCEPT
    #iptables -A FORWARD -i pppoe-wan${i} -j ACCEPT
    
    iptables -t mangle -A POSTROUTING -o pppoe-wan${i}  -m state --state NEW -j CONNMARK --set-mark ${i}
    iptables -t mangle -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
   #iptables -t mangle -A PREROUTING -i pppoe-wan${i}  -m state --state NEW -j CONNMARK --set-mark ${i}
    iptables -t mangle -A PREROUTING -i br-lan -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark

    iptables -t nat -A POSTROUTING -o pppoe-wan${i} -j SNAT --to ${IP_PPP}

done

eval "${ROUTECMD}" && echo "DONE"
./light.sh on

ip route flush cache

set +x
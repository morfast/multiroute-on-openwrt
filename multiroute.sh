#!/bin/sh

source /etc/profile
#set -x

if [ $# -eq 1 ]; then
	PPP_NUM=$1
fi

# disable the routing cache
echo -1 > /proc/sys/net/ipv4/rt_cache_rebuild_count

echo "testing ${PPP_NUM} connections"
TIMEOUT=$(( PPP_NUM / 2 + 9))
echo timeout: ${TIMEOUT}

count=0
while :
do
    NLINE=$(ifconfig | grep ${PPP_IF_PREFIX} | wc -l)
    if [ ${NLINE} -eq ${PPP_NUM} ]; then
        echo "Congratulations! All ${NLINE} connections established"
        break
    fi  

    sleep 1
    echo '.'
    count=$(( count + 1 ))
    if [ $count -gt ${TIMEOUT} ]; then
    	if [ ${NLINE} -le 0 ]; then
    	    echo "No connection established, trying with less connection number"
    	    pkill pppd
    	    pkill initppp
    	    pkill -f light.sh
    	    ./go.sh $((PPP_NUM-1))
    	    exit 1
    	fi
        NLINE=$(ifconfig | grep ${PPP_IF_PREFIX} | wc -l)
        echo "${NLINE} connections established"
    	pkill initppp
    	break
    fi
done

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
    ip rule add prio 20000 fwmark ${i} table P${i}
   #ip rule add prio 30000 from ${IP_PPP} table P${i}
    echo "OK"

    ROUTECMD="${ROUTECMD}nexthop via ${PPPGATE} dev ${PPP_IF_PREFIX}${i}  weight 1 \\
              "

    #iptables -A FORWARD -i ${PPP_IF_PREFIX}${i} -j ACCEPT
    
    echo -n "modify iptables rules ..."
    iptables -t mangle -A POSTROUTING -o ${PPP_IF_PREFIX}${i}  -m state --state NEW -j CONNMARK --set-mark ${i}
    iptables -t mangle -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
   #iptables -t mangle -A PREROUTING -i ${PPP_IF_PREFIX}${i}  -m state --state NEW -j CONNMARK --set-mark ${i}
    iptables -t mangle -A PREROUTING -i br-lan -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark

    iptables -t nat -A POSTROUTING -o ${PPP_IF_PREFIX}${i} -j SNAT --to ${IP_PPP}
    echo "OK"

done

echo -n "adding route for DNS ... "
for dns_server in ${DNS}
do
    ip route add ${dns_server} via ${PPPGATE}
done
echo "OK"

ip route flush cache

echo "Adding default route ... "
eval "${ROUTECMD}" && echo "ALL DONE"
./light.sh on

echo 
echo "=================Connections information==========================="
ip route | grep ${PPP_IF_PREFIX}
echo "==================================================================="


#set +x

#!/bin/sh

#set -x

if [ $# -eq 1 ]; then
	PPP_NUM=$1
fi

# disable the routing cache
echo -1 > /proc/sys/net/ipv4/rt_cache_rebuild_count

echo "testing ${PPP_NUM} connections"
TIMEOUT=$(( PPP_NUM / 2 + 9))
echo "timeout: ${TIMEOUT}"

count=0
while :
do
    NLINE=$(ifconfig | grep ${PPP_IF_PREFIX} | wc -l)
    if [ ${NLINE} -eq ${PPP_NUM} ]; then
    	echo
        echo "Congratulations! All ${NLINE} connections established"
        break
    fi  

    sleep 1
    echo -n '.'
    count=$(( count + 1 ))
    if [ $count -gt ${TIMEOUT} ]; then
    	if [ ${NLINE} -le 0 ]; then
            echo
    	    echo "No connection established, trying with less connection number"
    	    pkill pppd
    	    pkill initppp
    	    pkill -f light.sh
    	    ./go.sh $((PPP_NUM-1))
    	    exit 1
    	fi
        NLINE=$(ifconfig | grep ${PPP_IF_PREFIX} | wc -l)
	echo
        echo "${NLINE} connections established"
    	pkill initppp
    	break
    fi
done


#!/bin/sh

#set -x

if [ $# -eq 1 ]; then
	PPP_NUM=$1
fi

echo "testing ${PPP_NUM} connections"
TIMEOUT=$(( PPP_NUM / 2 + 9))
echo "timeout: ${TIMEOUT}"

count=0
while :
do
    NLINE=$(ifconfig | grep ${PPP_IF_PREFIX} | wc -l)
    echo -n ${NLINE}
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
    	    pkill syncpppinit
    	    pkill -f light.sh
    	    multiroute.sh $((PPP_NUM-1))
    	    exit 1
    	fi
        NLINE=$(ifconfig | grep ${PPP_IF_PREFIX} | wc -l)
	echo
        echo "${NLINE} connections established"
    	pkill syncpppinit
    	break
    fi
done


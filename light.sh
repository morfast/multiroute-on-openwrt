#!/bin/sh

qssgreen="/sys/devices/platform/leds-gpio/leds/tl-mr3x20:green:qss"
sysgreen="/sys/devices/platform/leds-gpio/leds/tl-mr3x20:green:system"

if [ $# -eq 0 ]; then
    exit 0
fi

if [ $1 == "blink" ]; then
    while :
    do
        echo 0 > ${qssgreen}/brightness
        msleep $2
        echo 1 > ${qssgreen}/brightness
        msleep $2
    done
elif [ $1 == "on" ]; then
    echo 1 > ${qssgreen}/brightness
elif [ $1 == "off" ]; then
    echo 0 > ${qssgreen}/brightness
fi
    
    



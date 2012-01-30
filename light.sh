#!/bin/sh

arch='tp-link'
qssgreen="/sys/devices/platform/leds-gpio/leds/${arch}:green:qss"
sysgreen="/sys/devices/platform/leds-gpio/leds/${arch}:green:system"

if [ $# -eq 0 -o ! -f $qssgreen -o ! -f $sysgreen ]; then
    exit 0
fi

if [ $1 == "blink" ]; then
    echo heartbeat > ${qssgreen}/trigger
elif [ $1 == "on" ]; then
    echo none > ${qssgreen}/trigger
    echo 1 > ${qssgreen}/brightness
elif [ $1 == "off" ]; then
    echo none > ${qssgreen}/trigger
    echo 0 > ${qssgreen}/brightness
fi


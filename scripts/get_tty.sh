#!/bin/bash
# use lsusb
# Bus 003 Device 002: ID 1a86:7523 QinHeng Electronics CH340 serial converter
# $1=003
# $2=002

valid=1

if [[ -z "$1" ]]; then 
  echo Bus number not supplied as first argument
  valid=0
fi

if [[ -z "$2" ]]; then 
  echo Device number not supplied as second argument
  valid=0
fi

if [[ $valid == 0 ]]; then 
  exit 1
fi

# make sure the device is not a hub
device_type=$(udevadm info --name=/dev/bus/usb/$1/$2 -a | grep "ATTR{bDeviceClass}==" | cut -d '=' -f3 | tr -d '"')
if [[ $device_type != "00" ]]; then
  echo "port not found" 1>&2
  exit 1
fi

tty=$(udevadm info --query=path --name=/dev/bus/usb/$1/$2 | xargs -I% find "/sys%" -name 'device' | xargs dirname 2> /dev/null | grep -F "/tty/" | xargs basename 2> /dev/null)

if [ $? -eq 0 ]; then
  echo $tty
else
  echo "port not found" 1>&2
  exit 1
fi


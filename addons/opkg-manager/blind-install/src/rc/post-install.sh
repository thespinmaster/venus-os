#!/bin/bash

if opkg list-installed opkg-manager; then
  echo "Already installed, nothing to do"
  exit 0
fi
 
mount -o remount,ro /
/opt/victronenergy/swupdate-scripts/resize2fs.sh

echo blind install - opkg-manager
opkg install https://thespinmaster.github.io/venus-os-addons/feeds/opkg-manager/opkg-manager-latest.ipk

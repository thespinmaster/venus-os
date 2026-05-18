#!/bin/bash

if opkg list-installed opkg-manager | grep -q opkg-manager; then
  echo "Already installed, nothing to do"
  exit 0
fi
 
mount -o remount,ro /
/opt/victronenergy/swupdate-scripts/resize2fs.sh

feed_config_file="/etc/opkg/opkg-manager-blind.conf"
feed_url="https://thespinmaster.github.io/venus-os/feeds/release/opkg-manager"
echo "src/gz opkg-manager-blind $feed_url" > "$feed_config_file"

opkg update
opkg install opkg-manager

rm -f $feed_config_file
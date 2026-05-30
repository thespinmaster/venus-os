#!/bin/bash

declare log_path=/var/logs/opkg-manager/
declare log=$log_path/blind-install.log

mkdir -p $log_path
exec > "$log" 2>&1

# Create a new log file for every run

if opkg list-installed opkg-manager; then
  echo "Already installed, nothing to do"
  exit 0
fi

echo "Running opkg-manager bind install"

mount -o remount,rw /
/opt/victronenergy/swupdate-scripts/resize2fs.sh

echo "installing- opkg-manager"
opkg install https://thespinmaster.github.io/venus-os-addons/feeds/release/opkg-manager/opkg-manager-latest.ipk

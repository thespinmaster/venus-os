#!/bin/bash

# exit on error
set -e

ensure_feed() {
  FEED_CONFIG_FILE="/etc/opkg/thespinmaster.conf"
  #FEED_CONFIG_FILE="./opkg_feeds/thespinmaster.conf"
  if [ -f $FEED_CONFIG_FILE ]; then
    echo "removing existing feed file"
    rm $FEED_CONFIG_FILE
  fi
  echo "adding opkg feed"
  FEED_URL="https://github.com/thespinmaster/venus-os/raw/refs/heads/main/feed"
  echo "src/gz thespinmaster ${FEED_URL}" > "${FEED_CONFIG_FILE}"

  opkg update
}

echo "resizing file system"
/opt/victronenergy/swupdate-scripts/resize2fs.sh

echo "ensuring spinmaster feed"
ensure_feed
opkg update

echo "replacing busybox"
opkg install packagegroup-replace-busybox

echo "installing python (full)"
opkg install python3

echo "installing support for mounting network shares"
opkg install mount-nfs-cifs

read -p "Enter hostname or IP address for dev share: " DEV_SERVER_IP
echo "mount dev share and link //${DEV_SERVER_IP}/dev to /data/dev"

if [[ -n ${DEV_SERVER_IP} ]]; then
  read -p "Enter username for dev share: " MOUNT_USER_NAME
  read -p "Enter password for dev share: " MOUNT_PASSWORD

  mkdir -p /mnt/storage/dev
  echo "mount -t cifs -o user=$MOUNT_USER_NAME,pass=$MOUNT_PASSWORD //${DEV_SERVER_IP}/dev /mnt/storage/dev" >> /data/mount-nfs-cifs/mountpoints.conf
  ln -s /mnt/storage/dev /data/dev
fi

cp /data/dev/projects/venus-os/scripts/dev-rc.local /data/rc.local

echo "setting up bash aliases"
/data/dev/projects/venus-os/scripts/ensure-bash-alias.sh

echo "dev environment setup completed successfully" 

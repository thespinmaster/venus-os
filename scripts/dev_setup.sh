#!/bin/bash

if [[ -z ${1} ]]; then
  echo "Server IP address or host name not passed"
  exit
fi

DEV_SERVER_IP=${1}

echo ${DEV_SERVER_IP}

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

echo "replacing busybox"
opkg install packagegroup-replace-busybox

echo "installing python (full)"
opkg install python3

echo "installing support for mounting network shares"
opkg install mount-nfs-cifs

echo "mount dev share and link to /data/dev"

mkdir -p /mnt/storage/dev
mount -t cifs //${DEV_SERVER_IP}/dev /mnt/storage/dev
ln -s /mnt/storage/dev /data/dev

# now we have access to /data/dev we can easily use our other scripts from /dev/scripts
echo "Link rc.local from scripts folder to data folder"

ln -s /data/dev/projects/venus-os/scripts/rc.local /data/rc.local

echo "mount -t cifs //${DEV_SERVER_IP}/dev /mnt/storage/dev" >> /data/ensure_mounts.sh
chmod +x /data/ensure_mounts.sh

/data/rc.local

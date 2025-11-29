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

echo "installing additional packages"
opkg install libatomic1

echo "installing support for mounting network shares"
opkg install mount-nfs-cifs

# () keeps . (source) to within bounds
(
  . /data/mount-nfs-cifs/mount-helpers.sh

  #source, username and password will be prompted for
  mount_cifs --target="/mnt/storage/dev"
)

if [[ ! -L "/data/dev" ]]; then
  ln -s "/mnt/storage/dev" "/data/dev"
fi

echo "setting up bash aliases"
(
  . /data/opkg-helpers/opkg-common.sh
  add_script_to_rc_local "/data/dev/projects/venus-os/scripts/ensure-bash-alias.sh"
  /data/dev/projects/venus-os/scripts/ensure-bash-alias.sh
)

echo "dev environment setup completed successfully" 

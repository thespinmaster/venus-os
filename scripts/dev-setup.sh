#!/bin/bash

# exit on error
set -e
 
ensure_feed() {

  FEED_CONFIG_FILE="/etc/opkg/thespinmaster.conf"
  if [ -f $FEED_CONFIG_FILE ]; then
    echo "removing existing feed file"
    rm $FEED_CONFIG_FILE
  fi
  echo "adding opkg feed"
  FEED_URL="https://github.com/thespinmaster/venus-os/raw/refs/heads/main/feed"
  echo "src/gz thespinmaster ${FEED_URL}" > "${FEED_CONFIG_FILE}"

}

echo "configuring file system"
mount -o remount,ro /
/opt/victronenergy/swupdate-scripts/resize2fs.sh

# make /data the default folder for connecting via sftp
# find 'Subsystem       sftp    /usr/libexec/sftp-server'
# and add '-d /data' to the end
sed 's#Subsystem\s*sftp\s*/usr/libexec/sftp-server#Subsystem       sftp    /usr/libexec/sftp-server -d /data#' /etc/ssh/sshd_config

# make data the default folder when logging in via ssh 
cat "cd /data" >> "~/.profile"

echo "ensuring spinmaster feed"
ensure_feed
opkg update

#TODO manualy add these packages to the /data/opkg-helpers/custom-packages.conf file
echo "replacing busybox"
opkg install packagegroup-replace-busybox

echo "installing python (full)"
opkg install python3

echo "installing additional packages"
opkg install libatomic1

echo "installing support for mounting network shares"
opkg install mount-shares

# () keeps . (source) to within bounds
(
  . /data/mount-shares/mount-helpers.sh

  #source, username and password will be prompted for
  # store mnt under /data and not /mnt as mnt may be readonly 
  mount_cifs --target="/data/mnt/storage/dev"
)

# if [[ ! -L "/data/dev" ]]; then
  ln -s "/data/mnt/storage/dev" "/data/dev"
fi

echo "setting up environment (bash aliases, nanorc config)"
(
  . /data/opkg-helpers/opkg-common.sh
  add_script_to_rc_local "
# setup enviroment (do not edit)
/data/dev/projects/venus-os/scripts/setup-environment.sh"
    
    # execute script
    /data/dev/projects/venus-os/scripts/setup-environment.sh
)

echo "dev environment setup completed successfully" 

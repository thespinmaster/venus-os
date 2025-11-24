#!/bin/bash

RC_LOCAL_FILE=/data/rc.local
OPKG_HELPERS_PATH=/data/opkg-helpers
OPKG_CUSTOM_PACKAGES_FILE=${OPKG_HELPERS_PATH}/custom-packages
OPKG_COMMON_SCRIPT_FILE=${OPKG_HELPERS_PATH}/opkg-common.sh

LOG=${OPKG_HELPERS_PATH}/log
IS_FS_READONLY=

expand_root_fs() {
  # Expand rootfs and make it writable
  /opt/victronenergy/swupdate-scripts/resize2fs.sh
}

is_root_fs_readonly() {
 V=$(grep "[[:space:]]ro[[:space:],]" /proc/mounts)
 if [ -z "${V}" ] ; then
   IS_FS_READONLY=false
 else
   IS_FS_READONLY=true
 fi
}

mount_root_fs_readwrite() {
  echo "mounting fs as read write" >> "${LOG}"
  mount -o remount,rw /
}

mount_root_fs_readonly() {
  echo "mounting fs as readonly" >> "${LOG}"
  mount -o remount,ro /
}

ensure_feed() {
  FEED_CONFIG_FILE="/etc/opkg/thespinmaster.conf"
  if [ ! -f $FEED_CONFIG_FILE ]; then
    echo "adding opkg feed" >> "${LOG}"
    FEED_URL="https://github.com/thespinmaster/venus-os/raw/refs/heads/main/feed"
    echo "src/gz thespinmaster ${FEED_URL}" > "${FEED_CONFIG_FILE}" 
  fi
}

try_install_package() {
  
  local PACKAGE_NAME
  local INSTALLED
  PACKAGE_NAME="${1}"
  
  if [[ -z "${PACKAGE_NAME}" ]]; then
    echo "package name not supplied"
    return 1
  fi

  # see if the ipk is installed
  INSTALLED=$(opkg list-installed "${PACKAGE_NAME}")
  #echo "Installed:${INSTALLED}"
  
  # if already installed then exit
  if [[ -n "${INSTALLED}" ]]; then
    echo "Already Installed ${PACKAGE_NAME}, exiting" >> "${LOG}"
    return 0
  fi
    
  if [[ -z ${IS_FS_READONLY} ]]; then 
    # make sure the file system is writeable

    is_root_fs_readonly
    echo "fs is readonly:${IS_FS_READONLY}" >> "${LOG}"

    if [ "${IS_FS_READONLY}" = true ]; then
      mount_root_fs_readwrite
    fi
    
    # ensure are feed is added to opkg
    # and update opkg
    ensure_feed
    opkg update >> "${LOG}"
  fi

  echo "Installing... ${PACKAGE_NAME}" >> "${LOG}"

  opkg install "${PACKAGE_NAME}" >> "${LOG}"

}

ensure_installed() {
  
  if [[ -f ${LOG} ]]; then
    rm ${LOG}
  fi  
  
  while IFS= read -r line
  do 
    if [[ ! -z "$line" ]]; then
      try_install_package "$line" 
    fi
  done < ${OPKG_CUSTOM_PACKAGES_FILE}

  if [ "${IS_FS_READONLY}" = true ]; then
    mount_root_fs_readonly
  fi

}

add_opkg_auto_installer_to_rc_local() {
  
  if ! grep -q "^# opkg-auto-installer (do not edit)$" "${RC_LOCAL_FILE}" ; then
    echo "adding opkg-auto-installer script to ${RC_LOCAL_FILE}" >> "${LOG}"
    
    echo "
# opkg-auto-installer (do not edit)
if [[ -f \"${OPKG_CUSTOM_PACKAGES_FILE}\" ]]; then
  noup \"${OPKG_COMMON_SCRIPT_FILE} ensure_installed\" &> /dev/null &
fi
" >> "${RC_LOCAL_FILE}"
  
  else
    echo "opkg-auto-installer script already added" >> "${LOG}"
  fi

}

add_package_name_to_custom_packages_file() {

  local PACKAGE_NAME
  PACKAGE_NAME="${1}"

  if ! grep -q "^$PACKAGE_NAME$" "$OPKG_CUSTOM_PACKAGES_FILE" ; then
    echo "adding ${PACKAGE_NAME} to ${OPKG_CUSTOM_PACKAGES_FILE}" >> "${LOG}"
    echo "${PACKAGE_NAME}" >> "${OPKG_CUSTOM_PACKAGES_FILE}"
  else
    echo "package '${PACKAGE_NAME}' already added" >> "${LOG}"
  fi

}

remove_package_name_from_custom_packages_file() {
  local PACKAGE_NAME
  PACKAGE_NAME="${1}"

  if grep -q "^${PACKAGE_NAME}$" "${OPKG_CUSTOM_PACKAGES_FILE}" ; then
    echo "Removing ${PACKAGE_NAME} from ${OPKG_CUSTOM_PACKAGES_FILE}" >> "${LOG}"
    sed -i "/^$PACKAGE_NAME$/d" "${OPKG_CUSTOM_PACKAGES_FILE}"
  else
    echo "package '${PACKAGE_NAME}' not found" >> "${LOG}"
  fi

}

if [[ ${1} == "ensure_installed" ]]; then
  ensure_installed
else if [[ ${1} == "postinst" ]]; then
  add_package_name_to_custom_packages_file ${2}
else if [[ ${1} == "postrm" ]]; then
  remove_package_name_from_custom_packages_file ${2}
fi

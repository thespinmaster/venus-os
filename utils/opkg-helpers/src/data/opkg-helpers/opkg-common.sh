#!/bin/bash

RC_LOCAL_FILE=/data/rc.local
OPKG_HELPERS_PATH=/data/opkg-helpers
OPKG_CUSTOM_PACKAGES_FILE=${OPKG_HELPERS_PATH}/custom-packages
OPKG_COMMON_SCRIPT_FILE=${OPKG_HELPERS_PATH}/opkg-common.sh

LOG=${OPKG_HELPERS_PATH}/log
IS_FS_READONLY=

log() {
  echo "`date +%y/%m/%d_%H:%M:%S`:: ${1}" >> "${LOG}"
}

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
  log "mounting fs as read write"
  mount -o remount,rw /
}

mount_root_fs_readonly() {
  log "mounting fs as readonly"
  mount -o remount,ro /
}

ensure_feed() {
  FEED_CONFIG_FILE="/etc/opkg/thespinmaster.conf"
  if [ ! -f $FEED_CONFIG_FILE ]; then
    log "adding opkg feed"
    FEED_URL="https://github.com/thespinmaster/venus-os/raw/refs/heads/main/feed"
    log "src/gz thespinmaster ${FEED_URL}"
  fi
}


try_install_package() {
  
  local PACKAGE_NAME
  local INSTALLED
  PACKAGE_NAME="${1}"
  
  if [[ -z "${PACKAGE_NAME}" ]]; then
    log "package name not supplied"
    return 1
  fi

  # see if the ipk is installed
  INSTALLED=$(opkg list-installed "${PACKAGE_NAME}")
  #echo "Installed:${INSTALLED}"
  
  # if already installed then exit
  if [[ -n "${INSTALLED}" ]]; then
    log "Already Installed ${PACKAGE_NAME}, exiting"
    return 0
  fi
    
  if [[ -z ${IS_FS_READONLY} ]]; then 
    # make sure the file system is writeable

    is_root_fs_readonly
    log "fs is readonly:${IS_FS_READONLY}"

    if [ "${IS_FS_READONLY}" = true ]; then
      mount_root_fs_readwrite
    fi
    
    # ensure are feed is added to opkg
    # and update opkg
    ensure_feed
    opkg update
  fi
  
  IS_FS_READONLY=

  log "Installing... ${PACKAGE_NAME}"  

  opkg install "${PACKAGE_NAME}"

}

ensure_installed() {
  
  if [[ -f "${LOG}" ]]; then
    rm "${LOG}"
  fi  
  
  while IFS= read -r line
  do 
    if [[ ! -z "$line" ]]; then
      try_install_package "$line" 
    fi
  done < "${OPKG_CUSTOM_PACKAGES_FILE}"

  if [ "${IS_FS_READONLY}" = true ]; then
    mount_root_fs_readonly
  fi

}

add_script_to_rc_local() {
  
  if [[ -z "${1}" ]]; then
    return
  fi

  if [[ ! -f ${RC_LOCAL_FILE} ]]; then
    echo "#!/bin/bash" >> ${RC_LOCAL_FILE}
    chmod +x ${RC_LOCAL_FILE}
  fi

  if grep -Fq "${1}" ${RC_LOCAL_FILE}; then
    log "custom script already added" 
  else
    log "adding custom script to ${RC_LOCAL_FILE}"
    
    echo "${1}" >> "${RC_LOCAL_FILE}"
  fi

}

remove_script_from_rc_local() {
  
  if [[ -z "${1}" ]]; then
    return
  fi

  if [[ ! -f ${RC_LOCAL_FILE} ]]; then
    return
  fi

  if grep -Fq "${1}" ${RC_LOCAL_FILE}; then
    log "removing custom script from ${RC_LOCAL_FILE}"  
    # muti-line file replace
    # may need different delimiter than |
    perl -i -0pe "s|\Q${1}\E||se" $RC_LOCAL_FILE 
  fi

}

add_package_name_to_custom_packages_file() {

  local PACKAGE_NAME
  PACKAGE_NAME="${1}"

  if ! grep -q "^${PACKAGE_NAME}$" "${OPKG_CUSTOM_PACKAGES_FILE}" ; then
    log "adding ${PACKAGE_NAME} to ${OPKG_CUSTOM_PACKAGES_FILE}"
    echo "${PACKAGE_NAME}" >> "${OPKG_CUSTOM_PACKAGES_FILE}"
  else
    log "package '${PACKAGE_NAME}' already added"
  fi

}

remove_package_name_from_custom_packages_file() {
  local PACKAGE_NAME
  PACKAGE_NAME="${1}"

  if grep -q "^${PACKAGE_NAME}$" "${OPKG_CUSTOM_PACKAGES_FILE}" ; then
    log "Removing ${PACKAGE_NAME} from ${OPKG_CUSTOM_PACKAGES_FILE}"
    sed -i "/^$PACKAGE_NAME$/d" "${OPKG_CUSTOM_PACKAGES_FILE}"
  else
    log "package '${PACKAGE_NAME}' not found"
  fi

}

if [[ ${1} == "ensure_installed" ]]; then
  ensure_installed
elif [[ ${1} == "postinst" ]]; then
  add_package_name_to_custom_packages_file ${2}
elif [[ ${1} == "postrm" ]]; then
  remove_package_name_from_custom_packages_file ${2}
elif [[ -n ${1} ]]; then
  log "invalid argument passed to opkg-common.sh"
fi

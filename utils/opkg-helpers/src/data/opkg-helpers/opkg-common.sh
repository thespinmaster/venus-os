#!/bin/bash

#TODO review readonly....need to change locations for testing?
readonly RC_LOCAL_FILE=/data/rc.local
readonly OPKG_HELPERS_PATH=/data/opkg-helpers
readonly OPKG_CUSTOM_PACKAGES_FILE=${OPKG_HELPERS_PATH}/custom-packages.conf
readonly OPKG_COMMON_SCRIPT_FILE=${OPKG_HELPERS_PATH}/opkg-common.sh
readonly LOG=${OPKG_HELPERS_PATH}/log
IS_FS_READONLY=
INIT_OPKG_HELPERS=
DRY_RUN=

. $(dirname ${BASH_SOURCE[0]})/log-helpers.sh

expand_root_fs() {
  # Expand rootfs and make it writable
  log "expanding root fs"
  if [ ! $DRY_RUN ]; then
    /opt/victronenergy/swupdate-scripts/resize2fs.sh
  fi
}

mount_root_fs_readwrite() {
  log "mounting fs as read write"
  if [ ! $DRY_RUN ]; then
    mount -o remount,rw /
  fi
}

mount_root_fs_readonly() {
  log "mounting fs as readonly"
  
  if [ ! $DRY_RUN ]; then 
    mount -o remount,ro / 
  fi

}

# pass initial state of IS_FS_READONLY
# if initial state is empty but IS_FS_READONLY now
# has a value then we restore back to readonly.
restore_previous_fs_access() {

  if [[ -z "${1}" ]]; then
     
    log "restoring previous fs state"

    if [[ "${FS_IS_READONLY}" = 1 ]]; then
      mount_root_fs_readonly
    else
      log "previous state was readwrite; nothing to restore"
    fi
    FS_IS_READONLY=
  fi

}

ensure_feed() {
  
  log "adding opkg feed"

  FEED_CONFIG_FILE="/etc/opkg/thespinmaster.conf"
  FEED_URL="https://github.com/thespinmaster/venus-os/raw/refs/heads/main/feed"
  FEED_CONTENT="src/gz thespinmaster ${FEED_URL}"

  if [ ! $DRY_RUN ]; then
    echo "${FEED_CONTENT}" > "${FEED_CONFIG_FILE}"
  else
    log "feed content:\"${FEED_CONTENT} > ${FEED_CONFIG_FILE}\"" 
  fi

}

ensure_rc_local() {
  log "ensure_rc_local"
  if [[ ! -f "${RC_LOCAL_FILE}" ]]; then
    log "rc.local does not exist; creating..."
    if [[ ! $DRY_RUN ]]; then
      log "#!/bin/bash" > "${RC_LOCAL_FILE}"
      chmod +x "${RC_LOCAL_FILE}"
    fi
  fi
}

init_root_fs_for_writing() {

  log "init_root_fs_for_writing"

  if [[ -z "${FS_IS_READONLY}" ]]; then

    # make sure the file system is writeable
    V=$(grep "[[:space:]]ro[[:space:],]" /proc/mounts)
    if [ -z "${V}" ] ; then
      FS_IS_READONLY=0
    else
      FS_IS_READONLY=1
    fi

    ###########
    FS_IS_READONLY=1

    if [ "${FS_IS_READONLY}" = 1 ]; then
      mount_root_fs_readwrite
    fi

    log "fs is readonly:${FS_IS_READONLY}"

  else
    log "FS_IS_READONLY already initialized"
  fi

}

init_opkg() {

  if [[ -z "${INIT_OPKG_HELPERS}" ]]; then  
    log "init_opkg: initializing"

    ensure_feed
    if [ ! $DRY_RUN ]; then
      opkg update
    fi

    INIT_OPKG_HELPERS=1
  else
    log "init_opkg: already initialzed"
  fi

}

ensure_installed() {

  log "ensure_installed"
  
  push_log_indent

  while IFS= read -r line
  do 
    # ignore comments and empty lines
    if [[ -z $(grep '^[[:blank:]]*[^[:blank:]#]' <<< "${line}" ) ]] || \
       [[ -z "${line}" ]]; then
      continue
    fi
    
    try_install_package "${line}"
  
  done < "${OPKG_CUSTOM_PACKAGES_FILE}"
  
  restore_previous_fs_access "${INIT_FS_IS_READONLY}"

  #log "FS_IS_READONLY=${FS_IS_READONLY} 'value should be empty'"

  pop_log_indent

  log "ensure_installed: done"
}

try_install_package() {

  log "try_install_package"
  
  PACKAGE_NAME="${1}"
  
  if [[ -z "${PACKAGE_NAME}" ]]; then
    log "package name not supplied"
    return 1
  fi

  # see if the ipk is installed
  # list-installed only returns an exact match
  INSTALLED=$(opkg list-installed "${PACKAGE_NAME}")
    
  # if already installed then exit
  if [[ -n "${INSTALLED}" ]]; then
    log "Already Installed ${PACKAGE_NAME}, exiting"
    return 0
  fi
  
  init_root_fs_for_writing
  init_opkg
  
  log "Installing... ${PACKAGE_NAME}"  
  if [ ! $DRY_RUN ]; then
    opkg install "${PACKAGE_NAME}"
  fi
}

add_script_to_rc_local() {
  
  if [[ -z "${1}" ]]; then
    log "no script supplied; exiting..."
    return
  fi
  
  ensure_rc_local
  
  . /data/opkg-helpers/string-helpers.sh
  local FOUND=
  FOUND=$(multiline_string_match "${1}" --find-only --break-on-first < "${RC_LOCAL_FILE}")

  if [[ ! $FOUND ]]; then
    log "adding custom script to ${RC_LOCAL_FILE}"
    if [ ! $DRY_RUN ]; then
      log "${1}" >> "${RC_LOCAL_FILE}"
    fi
  else
    log "custom script already added"
  fi

}

remove_script_from_rc_local() {

  if [[ -z "${1}" ]] || [[ ! -f ${RC_LOCAL_FILE} ]]; then
    log "no script supplied; exiting..."
    return
  fi

  . /data/opkg-helpers/string-helpers.sh
  log "removing custom script from ${RC_LOCAL_FILE}"

  # reads from ${RC_LOCAL_FILE} removes ${1} and saves back to ${RC_LOCAL_FILE}
  # multiline_string_match "${1}" --trim-lines < "${RC_LOCAL_FILE}" > "${RC_LOCAL_FILE}"
  
  if [ ! $DRY_RUN ]; then
    out=$(multiline_string_match "${1}" --trim-lines < "${RC_LOCAL_FILE}") && \
        log "$out" > "${RC_LOCAL_FILE}"
  fi

}

add_package_name_to_custom_packages_file() {

  local PACKAGE_NAME
  PACKAGE_NAME="${1}"

  if ! grep -q "^${PACKAGE_NAME}$" "${OPKG_CUSTOM_PACKAGES_FILE}" ; then
    log "adding ${PACKAGE_NAME} to ${OPKG_CUSTOM_PACKAGES_FILE}"
    if [ ! $DRY_RUN ]; then
      log "${PACKAGE_NAME}" >> "${OPKG_CUSTOM_PACKAGES_FILE}"
    fi
  else
    log "package ${PACKAGE_NAME} already added"
  fi

}

remove_package_name_from_custom_packages_file() {
  local PACKAGE_NAME
  PACKAGE_NAME="${1}"

  if grep -q "^${PACKAGE_NAME}$" "${OPKG_CUSTOM_PACKAGES_FILE}" ; then
    log "Removing ${PACKAGE_NAME} from ${OPKG_CUSTOM_PACKAGES_FILE}"
    if [ ! $DRY_RUN ]; then
      sed -i "/^$PACKAGE_NAME$/d" "${OPKG_CUSTOM_PACKAGES_FILE}"
    fi
  else
    log "package '${PACKAGE_NAME}' not found"
  fi

}

if [[ ${1} == "ensure_installed" ]]; then
  
  if [[ ${2} == "--dry-run" ]]; then
    DRY_RUN=1
    log "*** DRY RUN ***"
  fi
  
  ensure_installed

fi

ensure_rc_local_d_folder() {
  FOLDER_PATH=/data/opkg-helpers/rc.local.d/"${1}"
  mkdir -p "${FOLDER_PATH}"
  echo "${FOLDER_PATH}"
}

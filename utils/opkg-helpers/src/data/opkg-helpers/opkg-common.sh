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
  echo "mounting fs as read write"
  mount -o remount,rw /
}

mount_root_fs_readonly() {
  echo "mounting fs as readonly"
  mount -o remount,ro /
}

ensure_feed() {
  FEED_CONFIG_FILE="/etc/opkg/thespinmaster.conf"
  if [ ! -f "${FEED_CONFIG_FILE}" ]; then
    echo "adding opkg feed"
    FEED_URL="https://github.com/thespinmaster/venus-os/raw/refs/heads/main/feed"
    echo "${FEED_URL}" >> "${FEED_CONFIG_FILE}"
  else
    echo "found opkg feed ${FEED_CONFIG_FILE}"
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
    echo "Already Installed ${PACKAGE_NAME}, exiting"
    return 0
  fi
    
  if [[ -z ${IS_FS_READONLY} ]]; then 
    # make sure the file system is writeable

    is_root_fs_readonly
    echo "fs is readonly:${IS_FS_READONLY}"

    if [ "${IS_FS_READONLY}" = true ]; then
      mount_root_fs_readwrite
    fi
  
  fi
  
  IS_FS_READONLY=

  echo "Installing... ${PACKAGE_NAME}"  

  opkg install "${PACKAGE_NAME}"

}

ensure_rc_local() {
  if [[ ! -f ${RC_LOCAL_FILE} ]]; then
    echo "#!/bin/bash" >> ${RC_LOCAL_FILE}
    chmod +x ${RC_LOCAL_FILE}
  fi
}
ensure_installed() {
  
  if [[ -f "${LOG}" ]]; then
    rm "${LOG}"
  fi  
  
  # ensure custom feed is added and upto date
  ensure_feed
  opkg update

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

##############################################################
### An awk funtion to do simple multi-line string replacements
### strings can contain any special characters
### NO REGEX just simple exact matches
### 
##############################################################
awk_string_replace() {

  awk -v pattern="$1" '
    BEGIN {RS = ""; ORS = "";}

    {
        content = $0;
        match_pos = index(content, pattern);
        
        if (match_pos > 0) {
            # Rebuild the string: part before the match + part after the match
            len_pattern = length(pattern);
            new_content = substr(content, 1, match_pos - 1);
            new_content = new_content substr(content, match_pos + len_pattern);
            print new_content;
        } else {
            print content; # No match, print original content
        }
    }
' filename
}

add_script_to_rc_local() {
  
  if [[ -z "${1}" ]]; then
    return
  fi
  
  ensure_rc_local
  
  . ./string-helpers.sh
  local FOUND=
  FOUND=$(awk_contains_multiline_string "$SEARCH_PATTERN" <<< "$FILE_CONTENTS")

  if [[ ! $FOUND ]]; then
    echo "adding custom script to ${RC_LOCAL_FILE}"
    echo "${1}" >> "${RC_LOCAL_FILE}"
  else
    echo "custom script already added"
  fi
 
}

remove_script_from_rc_local() {
  
  if [[ -z "${1}" ]] || [[ ! -f ${RC_LOCAL_FILE} ]]; then
    return
  fi

  . ./string-helpers.sh
  echo "removing custom script from ${RC_LOCAL_FILE}"
  # reads from ${RC_LOCAL_FILE} removes ${1} and saves back to ${RC_LOCAL_FILE}
  awk_remove_multiline_string "$SEARCH_PATTERN" ${RC_LOCAL_FILE} > ${RC_LOCAL_FILE}
 
}

add_package_name_to_custom_packages_file() {

  local PACKAGE_NAME
  PACKAGE_NAME="${1}"

  if ! grep -q "^${PACKAGE_NAME}$" "${OPKG_CUSTOM_PACKAGES_FILE}" ; then
    echo "adding ${PACKAGE_NAME} to ${OPKG_CUSTOM_PACKAGES_FILE}"
    echo "${PACKAGE_NAME}" >> "${OPKG_CUSTOM_PACKAGES_FILE}"
  else
    echo "package '${PACKAGE_NAME}' already added"
  fi

}

remove_package_name_from_custom_packages_file() {
  local PACKAGE_NAME
  PACKAGE_NAME="${1}"

  if grep -q "^${PACKAGE_NAME}$" "${OPKG_CUSTOM_PACKAGES_FILE}" ; then
    echo "Removing ${PACKAGE_NAME} from ${OPKG_CUSTOM_PACKAGES_FILE}"
    sed -i "/^$PACKAGE_NAME$/d" "${OPKG_CUSTOM_PACKAGES_FILE}"
  else
    echo "package '${PACKAGE_NAME}' not found"
  fi

}

if [[ ${1} == "ensure_installed" ]]; then
  ensure_installed
elif [[ -n ${1} ]]; then
  echo "invalid argument passed to opkg-common.sh"
fi

#!/bin/bash

. /data/opkg-helpers/log-helpers.sh

DRY_RUN=

readonly MOUNT_POINT_CONF_FILE=~/mountpoints.conf

mount_shares() {

  log "mount_shares"
  
  if [[ ! -f ${MOUNT_POINT_CONF_FILE} ]]; then
    log "missing mountpoint.conf file"
    return
  fi
  
  push_log_indent

  local MOUNT_COMMAND
  local MOUNT_FOUND

  while IFS= read -r line; do
    [[ -n $line ]] && log "line=${line}"

    if [[ "${line}" == "#*" ]] || [[ -z "${line}" ]]; then
      continue
    fi

    MOUNT_COMMAND="${line}"

    log "calling mount_server: $MOUNT_COMMAND"

    if [[ -n "${MOUNT_COMMAND}" ]]; then
      MOUNT_FOUND=true
      mount_server "$MOUNT_COMMAND"
      MOUNT_COMAMND=
    fi

  done < "${MOUNT_POINT_CONF_FILE}"

  if [[ ! ${MOUNT_FOUND} ]]; then
    log "no mount points found in mountpoints.conf"
  fi
  
  pop_log_indent
  log "mount_shares done"
}

mount_server() {

  log "mount_server"

  MOUNT_COMMAND="${1}"

  # extract string between '//' and '/' to return IP '192.169.60.20' or 'hostname'
  SERVER=$(sed 's|.* //||; s|/.*||' <<< "$MOUNT_COMMAND")
  
  # extract string between '//' and ' ' to return IP '192.169.60.20/data/abc' or 'hostname/data/abc'
  SERVER_PATH=$(sed 's|.* //||; s| .*||' <<< "$MOUNT_COMMAND")
  
  # extract string after last space to get mount path '/data/dev' or other
  MOUNT_POINT="${MOUNT_COMMAND##* }"

  if [[ -z "${SERVER}" ]] || [[ -z "${SERVER_PATH}" ]] || [[ -z "${MOUNT_POINT}" ]]; then
    log "mount_server: invaid args"
    return
  fi
  
  push_log_indent

  # if mountpoint returns anything else but 0 then re-mount (-q=quiet)
  # store return value in RETVAL and return true on error.
  # otherwise if 'set -e' is used we will exit
  mountpoint -q "${MOUNT_POINT}" && RETVAL=0 || { RETVAL=$?; true; }

  if [[ ${RETVAL} -ne 0 ]]; then
    log "not mounted...mounting"
    
   if [[ $(ping -q -c1 -W 1 ${SERVER} >>/dev/null && echo 0 || true) ]]; then

      log "server ${SERVER} is up"
      log "mounting... ${SERVER_PATH} to ${MOUNT_POINT}"

      if [[ ! -d "${MOUNT_POINT}" ]]; then
        log "creating mountpoint folder... ${MOUNT_POINT}"
        if [[ ! ${DRY_RUN} ]]; then
          mkdir -p "${MOUNT_POINT}"
        fi
      else
        log "mountpoint folder already exists... ${MOUNT_POINT}"
      fi
      
      if [[ ! ${DRY_RUN} ]]; then
        eval "${MOUNT_COMMAND}"
      fi

      # check mount succeeded
      mountpoint -q "${MOUNT_POINT}" && RETVAL=0 || { RETVAL=$?; true; } ## always return true
      if [[ ${RETVAL} -eq 0 ]]; then
        log "mount point succeeded"
      else
        log "mount point failed"
      fi

    else
       log "server ${SERVER} is down"
    fi

  else
    log "mount point already exists"
  fi

  pop_log_indent

  log "mount server done"
}

mount_cifs() {

  local SOURCE=
  local TARGET=
  local USERNAME=
  local PASSWORD=

  while [ $# -gt 0 ]; do
    case "$1" in
      --source*|-s*)
        if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
        SOURCE="${1#*=}"
        ;;
      --target*|-t*)
        if [[ "$1" != *=* ]]; then shift; fi
        TARGET="${1#*=}"
        ;;
      --username*|-u*)
        if [[ "$1" != *=* ]]; then shift; fi
        USERNAME="${1#*=}"
        ;;
      --password*|-p*)
        if [[ "$1" != *=* ]]; then shift; fi
        PASSWORD="${1#*=}"
        ;;
      --help|-h)
        HELP='Creates a cifs mount point and stores the settings to the
mountpoints.conf file. The mount_all function is called from
rc.local (at startup) and reads the mountpoints.conf file to mount
the stored mountpoints.

if any arguments are missing (-s,-t,-u,-p) the values are prompted for.

  Version 1.0

  Arguments:
    --source | -s : The source of the mountpoint. i.e. //192.168.2.1/data or //hostname/data
    --target | -t : The local target for the mountpoint. i.e. /mnt/data
    --username | -u: The user name to access the source.
    --password | -p : The password used to access the source.
    --options  | -o : any additional options. i.e. ",someoption -rw"
'

        printf "${HELP}"
        exit 0
        ;;
      *)
        >&2 printf "Error: Invalid argument\n"
        exit 1
        ;;
    esac
    shift
  done

  if [[ -z "${SOURCE}" ]]; then
    read -p "Enter server ip/host address and path: " SOURCE
  fi

  if [[ -z "${TARGET}" ]]; then
    read -p "Enter local mount point path: " TARGET
  fi

  if [[ -z "${USERNAME}" ]]; then
    read -p "Enter username for share: " USERNAME
  fi

  if [[ -z "${PASSWORD}" ]]; then
    read -s -p "Enter password for share: " PASSWORD
    echo
  fi

  if [[ -z "${SOURCE}" ]] || [[ -z "${TARGET}" ]]; then
    echo "exiting..."
    return
  fi

  if [[ ! -d "${TARGET}" ]]; then
    mkdir -p "${TARGET}"
  fi

  if [[ "${SOURCE:0:2}" != "//" ]]; then
    SOURCE="//${SOURCE}"
  fi

  MOUNT_COMMAND="mount -t cifs -o user=${USERNAME},pass=${PASSWORD} ${OPTIONS} ${SOURCE} ${TARGET}"
  
  if grep -Fq "${MOUNT_COMMAND}" "${MOUNT_POINT_CONF_FILE}"; then
    log "mount already added to mountpoints.conf"
  else
    log "added mount to mountpoints.conf"
    if [[ ! ${DRY_RUN} ]]; then
      echo "${MOUNT_COMMAND}" >> "${MOUNT_POINT_CONF_FILE}"
    fi
  fi

  mount_server "${MOUNT_COMMAND}"
}

if [[ "${1}" == "mount_shares" ]]; then

  if [[ ${2} == "--dry-run" ]]; then
    DRY_RUN=1
    log "*** DRY RUN ***"
  fi

  mount_shares

elif [[ "${1}" == "mount_cifs" ]]; then
  shift
  mount_cifs "$@"
fi


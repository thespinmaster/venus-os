#!/bin/bash

SERVER_UP=
MOUNT_POINT_CONF_FILE=$(realpath mountpoints.conf)

wait_for_server() {

  echo "waiting for Server ${1}..."
  i=0
  
  while ! timeout .2 ping -c 1 -n "${1}" &> /dev/null
  do
    i=$((i+1))
    #echo "wait_for_server:" ${i}
    if [[ ${i} -eq 20 ]]; then
      SERVER_UP=false
      break
    fi
  done

  if [[ -z "${SERVER_UP}" ]]; then
    echo "server  ${1} is up"
    SERVER_UP=true
  else
    echo "server  ${1} is down"
  fi

}

mount_all() {
  
  if [[ ! -f ${MOUNT_POINT_CONF_FILE} ]]; then
    echo "missing mountpoint.conf file"
    return  
  fi

  local MOUNT_COMMAND
  local MOUNT_FOUND

  while IFS= read -r line; do
    [[ -n $line ]] && echo "line=${line}"

    if [[ "${line}" == "#*" ]] || [[ -z "${line}" ]]; then
      continue
    fi
    
    MOUNT_COMMAND="${line}"

    echo "calling mount_server: $SERVER, $SERVER_PATH, $MOUNT_POINT"

    if [[ -n "${MOUNT_POINT}" ]]; then
      MOUNT_FOUND=true
      mount_server "$MOUNT_COMMAND"
      MOUNT_COMAMND=
    fi

  done < "${MOUNT_POINT_CONF_FILE}"
  
  if [[ ${MOUNT_FOUND} = true ]]; then
    echo "no mount points found in mountpoints.conf"
  fi

}

mount_server() {

  MOUNT_COMMAND="${1}"
  SERVER=$(grep -o -P '(?<= //).*?(?=/)' <<< "${MOUNT_COMMAND}")
  SERVER_PATH=$(grep -o -P '(?<= //).*?(?= )' <<< "${MOUNT_COMMAND}")
  MOUNT_POINT="${MOUNT_COMMAND##* }"

  if [[ -z "${SERVER}" ]] || [[ -z "${SERVER_PATH}" ]] || [[ -z "${MOUNT_POINT}" ]]; then
    echo "mount_server: invaid args"
    return
  fi

  #if mountpoint returns anything else but 0 then re-mount (-q=quiet)
  mountpoint -q "${MOUNT_POINT}"
    
  if [[ $? -ne 0 ]]; then
    echo "not mounted...mounting"
    SERVER_UP=
    wait_for_server "${SERVER}"
    if [[ ${SERVER_UP} == true ]]; then
      echo "mounting... ${SERVER_PATH} to ${MOUNT_POINT}"
      eval ${MOUNT_COMMAND}
      mountpoint -q ${MOUNT_POINT}
      if [[ $? -eq 0 ]]; then
        echo "mount point succeeded"
      else
        echo "mount point failed"
      fi
    fi
 
  else
    echo "mount point already exists"
  fi
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
        HELP="Creates a cifs mount point and stores the settings to the 
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
    --options  | -o : any additional options. i.e. \",someoption -rw\"
"
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
    echo "mount already added to mountpoints.conf"
  else
    echo "${MOUNT_COMMAND}" >> "${MOUNT_POINT_CONF_FILE}"
  fi
  mount_server "${MOUNT_COMMAND}"
}

if [[ "${1}" == "mount_all" ]]; then
  mount_all
elif [[ "${1}" == "mount_cifs" ]]; then
  shift
  mount_cifs "$@"
fi



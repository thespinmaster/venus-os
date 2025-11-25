#!/bin/bash

SERVER_UP=
MOUNT_POINT_CONF_FILE=/data/mount-nfs-cifs/mountpoints.conf

function wait_for_server() {

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

function mount_servers() {
  
  if [[ ! -f ${MOUNT_POINT_CONF_FILE} ]]; then
    echo "missing mountpoint.conf file"
    return  
  fi

  local SERVER
  local SERVER_PATH
  local MOUNT_POINT
  local MOUNT_COMMAND
  local MOUNT_FOUND

  while IFS= read -r line; do
    [[ -n $line ]] && echo "line=${line}"

    if [[ "${line}" == "#*" ]] || [[ -z "${line}" ]]; then
      continue
    fi
    
    MOUNT_COMMAND="${line}"
    SERVER=$(grep -o -P '(?<= //).*?(?=/)' <<< "${MOUNT_COMMAND}")
    SERVER_PATH=$(grep -o -P '(?<= //).*?(?= )' <<< "${MOUNT_COMMAND}")
    MOUNT_POINT="${MOUNT_COMMAND##* }"

    echo "calling mount_server: $SERVER, $SERVER_PATH, $MOUNT_POINT"

    if [[ -n "${SERVER}" ]] && [[ -n "${SERVER_PATH}" ]] && [[ -n "${MOUNT_POINT}" ]]; then
      MOUNT_FOUND=true
      mount_server "$SERVER" "$SERVER_PATH" "$MOUNT_POINT" "$MOUNT_COMMAND"
      
      SERVER=
      SERVER_PATH=
      MOUNT_POINT=
      MOUNT_COMAMND=
    fi

  done < mountpoints.conf  
  
  if [[ ${MOUNT_FOUND} == true ]]; then
    echo "no mount points found in mountpoints.conf"
  fi

}

function mount_server() {

  #if mountpoint returns anything else but 0 then re-mount (-q=quiet)
  mountpoint -q "${3}"
    
  if [[ $? -ne 0 ]]; then
    echo "not mounted...mounting"
    SERVER_UP=
    wait_for_server "${1}"
    if [[ ${SERVER_UP} == true ]]; then
      echo "mounting... ${2} to ${3}"
      eval '${4}'
      mountpoint -q "${3}"
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


mount_servers

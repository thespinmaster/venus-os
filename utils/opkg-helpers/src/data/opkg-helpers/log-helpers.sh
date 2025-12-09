#!/bin/bash

# usage
# export OPKGH_LOG_FILE=$(/data/opkg-helpers/log-helpers.sh "init_logging" "/data/rc.local.log")

INDENT=

log() {
  
  if [[ -f "${OPKGH_LOG_FILE}" ]]; then
    #log "`date +%y/%m/%d_%H:%M:%S`:: ${1}" >> "${OPKGHLOG_FILE}"
    echo "${INDENT}${1}" >> "${OPKGH_LOG_FILE}"
  else
    echo "${INDENT}${1}"
  fi
}

pop_log_indent() {
  set_indent $((${#INDENT}-1))
}

push_log_indent() {
  set_indent $((${#INDENT}+1))
}

set_indent() {

  INDENT_LEN=${1} 
  INDENT=

  if [[ INDENT_LEN -gt 0 ]]; then
    for((i=0; i<${INDENT_LEN}; i++)); do
      INDENT="${INDENT} "
    done
  fi
}

init_logging() {
  echo "*** `date +%y/%m/%d_%H:%M:%S` ***" > "${1}"
}


if [[ "${1}" == "init_logging" ]]; then
  echo "${init_logging "${2}"}"
  echo "${2}"
fi

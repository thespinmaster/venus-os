#!/usr/bin/env bash

##############################################################################
# time out the udevadm call after x seconds
# note timeout command does not exist in venus-os
# udevadm monitor --subsystem-match=tty -u
#   monitor udev events for the tty subsystem
#   returns when a usb device is removed/added
# UDEV  [35.676607] remove   /devices/platform/scb/.../usb1/1-1/1-1.3/1-1.3:1.0/ttyUSB1/tty/ttyUSB1 (tty)
# UDEV  [38.949135] add      /devices/platform/scb/.../usb1/1-1/1-1.3/1-1.3:1.0/ttyUSB1/tty/ttyUSB1 (tty)
##############################################################################

result_file=
readusb_pid=

cleanup () {
  test -f "$result_file" && rm "$result_file"
  if [[ $readusb_pid ]]; then
    kill -- -$readusb_pid 2>/dev/null
  fi
}

trap cleanup EXIT

declare -i arg_timeout=10 # default to 10 seconds

printhelp() {
  cat <<EOF
Detects and returns the port name (ttyXXXX) when a new usb device is plugged in.

  Version 1.1

  Usage
  get_usb_port [-t | -timeout (n seconds)] [-s | --silent] [-e --eval (string command)]

  Arguments
  --timeout | -t : Timeout for pluging in the usb device default is 10 seconds
  --silent  | -s : Only output the result
  --eval    | -e : A string containing commands that get and output a tty port name e.g. 'echo ttyUSB0'
EOF
}

while [ $# -gt 0 ]; do
  case "${1}" in
    --silent*|-s*) arg_silent=1 ;;
    --timeout*|-t*) shift; arg_timeout="${1#*=}" ;;
    --help|-h) printhelp; exit 0 ;;
    -*) >&2 printf "Error: Invalid argument\n"; exit 1 ;;
    *) break ;;
  esac
  shift
done

test ${arg_timeout} -lt 1 && { printf "Error: Invalid argument [-t --timeout] \n"; exit 1; }
test ! $arg_silent && printf "Plug in (or re-plugin) the usb device now...timeout in ${arg_timeout} seconds\n"

result_file=/tmp/$PPID.result
rm -f "$result_file" 2>/dev/null # should never happen

set -m
(
  if [[ $arg_eval ]]; then
    #need to use an intermeadiate file here as the file is created immediately.
    # otherwise we would exit before any sleep statments ect.
    eval "$@ >$result_file"
    exit 0
  fi

  UDEV="UDEV  [38.949135] add      /devices/platform/scb/usb1/1-1/1-1.3/1-1.3:1.0/ttyUSB1/tty/ttyUSB1 (tty)"
  udm_output=$(sleep 3; echo "$UDEV" | grep -E '(^UDEV .*\[[0-9]*\.[0-9]*\] add )')
  #udm_output="$(udevadm monitor --subsystem-match=tty -u | grep -E '(^UDEV .*\[[0-9]*\.[0-9]*\] add )')"
  if [[ -n "${udm_output}" ]]; then
    udm_output="${udm_output##*'/'}" # return everythng after the last '/'
    udm_output="${udm_output% *}"    # trim ' (tty)' from the end
  fi
  echo "$udm_output" >"$result_file"

) &

readusb_pid=$!
set +m

t=$arg_timeout
while ((t > 0)); do
  [[ -f "${result_file}" ]] && break || { sleep 1; ((t -= 1)); }
done

[[ -f "$result_file" ]] && { echo $(<"$result_file"); } || { test ! $arg_silent && echo "No device detected"; }


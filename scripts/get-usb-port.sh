
while [ $# -gt 0 ]; do
  case "$1" in
    --silent*|-s*)
      SILENT="TRUE"
      ;;
    --timeout*|-t*)
      if [[ "$1" != *=* ]]; then shift; fi
      TIMEOUT="${1#*=}"
      ;;
    --help|-h)
      HELP="Returns the port name (ttyXXXX) when a new usb device is plugged in.
  
  Version 1.1
  
  Arguments:  
  --timeout | -t : Timeout for pluging in the usb device default is 10 seconds
  --silent  | -s : Only output the result  
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

if [[ -z "$TIMEOUT" ]]; then
  TIMEOUT=10
fi

if [[ -z "$SILENT" ]]; then
  echo "plug in (or re-plugin) the usb device now...timeout in ${TIMEOUT} seconds"
fi

##############################################################################
# Notes
# $(echo ...) 
#   needed, else variable TTY does not get set
# timeout ${TIMEOUT} 
# time out the udevadm call after x seconds
# udevadm monitor --subsystem-match=tty -u 
#   monitor udev events for the tty subsystem
#   returns when a usb device is removed/added 
# UDEV  [35.676607] remove   /devices/platform/scb/.../usb1/1-1/1-1.3/1-1.3:1.0/ttyUSB1/tty/ttyUSB1 (tty)
# UDEV  [38.949135] add      /devices/platform/scb/.../usb1/1-1/1-1.3/1-1.3:1.0/ttyUSB1/tty/ttyUSB1 (tty)
#
# grep -P '(?=^UDEV .*\[[0-9]*\.[0-9]*\] add )'
#    filters out all events except the add event
# xargs -d "\n" -i sh -c 'f="{}"; basename "${f::-5}" ' 2>/dev/null 
#    set the passed args to var f (so we can trim it)
# remove the subsystem marker at the end of the string " (tty)" with "${f::-6}"
# finaly call basename to return just the folder name "ttyUSB0" or similar
##############################################################################

TTY=$(echo "$(timeout ${TIMEOUT} udevadm monitor --subsystem-match=tty -u | \
              grep -P '(?=^UDEV .*\[[0-9]*\.[0-9]*\] add )')" | \
              xargs -d "\n" -i sh -c 'f="{}"; basename "${f::-5}" ' 2>/dev/null)

if [[ -z "$TTY" ]]; then
  if [[ -z "$SILENT" ]]; then
    echo "No device detected"
  fi
else
  echo "${TTY}"
fi

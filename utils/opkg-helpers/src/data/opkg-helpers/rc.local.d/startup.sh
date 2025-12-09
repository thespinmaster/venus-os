#!/bin/bash

. /data/opkg-helpers/log-helpers.sh

export OPKGH_LOG_FILE=/data/opkg-helpers/rc.local.d/startup.log
init_logging "${OPKGH_LOG_FILE}"

pushd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null
                                         
# needed for +([0-9]) part of the find call below
shopt -s extglob

# find and execute all script files in alpha-numeric order
for f in $(find ./+([0-9]) -type f | sort -V); do
  log "***************************"
  log "execuing... $f"
  "$f" || true
  log "***************************"
  log " "
done

unset OPKGH_LOG_FILE

popd >/dev/null
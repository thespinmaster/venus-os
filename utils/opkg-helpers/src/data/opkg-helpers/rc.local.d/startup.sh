#!/bin/bash

. /data/opkg-helpers/log-helpers.sh

export OPKGH_LOG_FILE=/data/opkg-helpers/rc.local.d/startup.log
init_logging "${OPKGH_LOG_FILE}"

# needed for +([0-9]) part of the find call below
shopt -s extglob

# find and execute all script files in alpha-numeric order
for f in $(find "$PWD/"+([0-9]) -type f | sort -V); do
  log "execuing... $f"
  push_indent
  "$f" || true
  pop_indent
done

unset OPKGH_LOG_FILE

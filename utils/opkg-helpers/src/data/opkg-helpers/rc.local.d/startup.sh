#find rc.local.d -type f | sort -V

. /data/opkg-helpers/log-helpers.sh
export OPKGH_LOG_FILE=/data/opkg-helpers/rc.local.d/startup.log
init_logging

# find and execute all script files in alpha-numeric order
for f in $(find ./+([0-9]) -type f | sort -V); do
  log "execuing... $f"
  "$f" || true
done


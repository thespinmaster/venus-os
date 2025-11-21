ensure_feed() {
  FEED_CONFIG_FILE="/etc/opkg/thespinmaster.conf"
  #FEED_CONFIG_FILE="./opkg_feeds/thespinmaster.conf"
  if [ ! -f $FEED_CONFIG_FILE ]; then
    echo "adding opkg feed"
    FEED_URL="https://github.com/thespinmaster/venus-os-configuration/raw/refs/heads/main/feed"
    echo "src/gz thespinmaster ${FEED_URL}" > "${FEED_CONFIG_FILE}" 
  fi
  opkg update
}

ensure_feed

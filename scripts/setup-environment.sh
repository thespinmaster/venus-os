# sets up any custom environment settings
# called from /data/rc.local and dev-setup

####################################################
RELOAD_BASH=
ALIAS_FILE=/etc/profile.d/my-alias.sh
if [ ! -L "${ALIAS_FILE}" ]; then
  echo "creating ${ALIAS_FILE} symbolic link"
  ln -s /data/dev/projects/venus-os/scripts/my-alias.sh "${ALIAS_FILE}"
  echo "reloading bash"
  RELOAD_BASH=1
fi

NANORC_FILE=/etc/nanorc
if [[ "$(readlink "${NANORV_FILE}")" != "/data/dev/projects/venus-os/scripts/nanorc" ]]; then
  echo "creating ${NANORC_FILE} symbolic link"
  rm -f "${NANORC_FILE}"
  ln -s /data/dev/projects/venus-os/scripts/nanorc "${NANORC_FILE}"
fi

# Keep at the end of the script
if [[ RELOAD_BASH ]]; then
  bash -l
fi

# ensures the alias file exists
# called from /data/rc.local and setup

ALIAS_FILE=/etc/profile.d/my-alias.sh
if [ ! -L "${ALIAS_FILE}" ]; then
  echo "creating /data/dev/projects/venus-os/scripts/my-alias.sh link"
  ln -s /data/dev/projects/venus-os/scripts/my-alias.sh "${ALIAS_FILE}"
  echo "reloading bash"
  bash -l
fi

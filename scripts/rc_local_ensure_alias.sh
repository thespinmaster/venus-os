# ensures the alias file exists
# called from /data/rc.local

ALIAS_FILE=/etc/profile.d/my_alias.sh
if [ ! -f "${ALIAS_FILE}" ]; then
  ln -s /data/dev/scripts/my_alias.sh "${ALIAS_FILE}"
fi

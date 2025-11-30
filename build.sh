
read -p "comment:" COMMENT

if [[ -z "${COMMENT}" ]]; then
  COMMENT="updated installer"
fi

git commit -am "${COMMENT}"
sudo git push

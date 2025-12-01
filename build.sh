

if [[ -n "$1" ]]; then
  build=all
else
 build="$1"
fi

read -p "comment:" COMMENT

if [[ -z "${COMMENT}" ]]; then
  COMMENT="updated installer"
fi

make $build
git commit -am "${COMMENT}"
sudo git push

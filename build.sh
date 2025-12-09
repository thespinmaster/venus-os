

if [[ -z "${1}" ]]; then
  build=all
elif [[ "${1}" != "-" ]]; then
  build="${1}"
fi

read -p "comment [updated installer]: " COMMENT
COMMENT=${COMMENT:-'updated installer'}

if [[ -n "${}" ]]; then
  make $build
fi

git add .
git commit -am "${COMMENT}"
git push

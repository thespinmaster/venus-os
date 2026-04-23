# copy or link to /etc/profile.d/my-alias.sh via /data/rc.local

alias list_alias="cat /data/dev/scripts/my-alias.sh"
alias nano_alias="nano /data/dev/scripts/my-alias.sh; . /home/root/.bashrc"

dev() {
  if [[ "${1:-}" == "shell" && "${2:-}" == "shorten" ]]; then
    PS1="\W# "
    export PS1
    return 0
  fi

  /data/dev/scripts/dev-helper "$@"
}

alias shorten='PS1="\W# "'
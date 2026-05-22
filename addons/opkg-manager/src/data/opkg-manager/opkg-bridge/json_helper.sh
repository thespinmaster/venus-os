#!/bin/bash

set -o nounset
set -o pipefail

QML_FILE_SERVER_DIR="/tmp/opkg-manager"
OPKG_FEEDS_JSON_CACHE_FILE="$QML_FILE_SERVER_DIR/feeds.json"
OPKG_ALL_PACKAGES_JSON_CACHE_FILE="$QML_FILE_SERVER_DIR/packages.json"
OPKG_FEEDS_FILE="/etc/opkg/opkg-manager.conf"

CACHE_UP_TO_DATE=0
CACHE_UPDATE_FEEDS=1
CACHE_UPDATE_ALL_PACKAGES=2

trim_ws() {
  local s="${1-}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

json_escape() {
  local s="${1-}"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

# shellcheck disable=SC2120
ensure_feed_config() {
  local feed_type="${1:-release}"
  local source="/data/conf/opkg-manager-${feed_type}.conf"

  if [[ -L "$OPKG_FEEDS_FILE" && -e "$source" ]]; then
    return 0
  fi

  if [[ -e "$source" ]]; then
    ln -s "$source" "$OPKG_FEEDS_FILE" 2>/dev/null || true
  fi
}

update_packages() {
  opkg update >/dev/null 2>&1
  return $?
}

get_mtime() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 1
  fi
  stat -c '%Y' "$path" 2>/dev/null || return 1
}

create_json_feeds_list() {
  local feeds_file="$1"
  local cache_file="$2"
  local manager_feed_name="${3:-opkg-manager}"
  local feeds_mtime cache_mtime

  if [[ -f "$cache_file" && -f "$feeds_file" ]]; then
    feeds_mtime=$(get_mtime "$feeds_file") || feeds_mtime=""
    cache_mtime=$(get_mtime "$cache_file") || cache_mtime=""
    if [[ -n "$feeds_mtime" && -n "$cache_mtime" && "$cache_mtime" -ge "$feeds_mtime" ]]; then
      return 0
    fi
  fi

  mkdir -p "$(dirname "$cache_file")"
  local tmp_file
  tmp_file=$(mktemp)
  printf '[' >"$tmp_file"

  local first=1
  if [[ -f "$feeds_file" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      [[ "$line" == \#* ]] && continue
      [[ "$line" != src/gz\ * ]] && continue

      local rest name url
      rest=${line#src/gz }
      name=${rest%%[[:space:]]*}
      url=${rest#"$name"}
      url=${url##[[:space:]]}

      [[ -z "$name" || -z "$url" ]] && continue

      (( first )) || printf ',' >>"$tmp_file"
      first=0
      printf '{"name":"%s","url":"%s","builtin":%s}' \
        "$(json_escape "$name")" \
        "$(json_escape "$url")" \
        "$([[ "$name" == "$manager_feed_name" ]] && echo true || echo false)" >>"$tmp_file"
    done <"$feeds_file"
  fi

  printf ']\n' >>"$tmp_file"
  mv "$tmp_file" "$cache_file"
}
 
create_installed_lookup() {
  local out_lookup_name="$1"
  local -n out_lookup_ref="$out_lookup_name"

  out_lookup_ref=()
  [[ -f /usr/lib/opkg/status ]] || return 0

  local pkg="" ver="" status="" line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
      if [[ -n "$pkg" && " $status " == *" installed "* ]]; then
        out_lookup_ref["$pkg"]="$ver"
      fi
      pkg=""
      ver=""
      status=""
      continue
    fi

    [[ "$line" == *:* ]] || continue
    key=${line%%:*}
    value=$(trim_ws "${line#*:}")
    case "$key" in
      Package) pkg="$value" ;;
      Version) ver="$value" ;;
      Status) status="$value" ;;
    esac
  done </usr/lib/opkg/status

  if [[ -n "$pkg" && " $status " == *" installed "* ]]; then
    out_lookup_ref["$pkg"]="$ver"
  fi
}

map_opkg_list_files_to_json() {
  local output_file="$1"
  local  -n allowed_fields_input_ref="$2"
  local  -n list_files_ref="$3"
 
  mkdir -p "$(dirname "$output_file")"
  local tmp_file
  tmp_file=$(mktemp)

  local -A allowed_fields=()
  local -i allowed_count=0
  local field_name
  for field_name in "${allowed_fields_input_ref[@]}"; do
    field_name=$(trim_ws "$field_name")
    [[ -z "$field_name" ]] && continue
    allowed_fields["$field_name"]=1
    allowed_count=$((allowed_count + 1))
  done

  local -A installed_lookup=()
  create_installed_lookup installed_lookup

  printf '[' >"$tmp_file"
  local -i first_json=1

  local list_file feed line key value nk current pkg installed_version
  local -i have_entry
  local last_key
  local -A fields=()
  local -A seen_keys=()
  local -a key_order=()

  for list_file in "${list_files_ref[@]}"; do
    [[ -f "$list_file" ]] || continue
    feed=${list_file##*/}

    fields=()
    seen_keys=()
    key_order=()
    have_entry=0
    last_key=""

    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ -z "$line" ]]; then
        if (( have_entry )); then
          pkg="${fields[package]-}"
          installed_version="${installed_lookup[$pkg]-}"

          (( first_json )) || printf ',' >>"$tmp_file"
          first_json=0

          printf '{' >>"$tmp_file"
          local -i first_field=1
          for nk in "${key_order[@]}"; do
            (( first_field )) || printf ',' >>"$tmp_file"
            first_field=0
            printf '"%s":"%s"' "$(json_escape "$nk")" "$(json_escape "${fields[$nk]}")" >>"$tmp_file"
          done
          (( first_field )) || printf ',' >>"$tmp_file"
          printf '"installed_version":"%s","feed":"%s"' \
            "$(json_escape "$installed_version")" \
            "$(json_escape "$feed")" >>"$tmp_file"
          printf '}' >>"$tmp_file"
        fi

        fields=()
        seen_keys=()
        key_order=()
        have_entry=0
        last_key=""
        continue
      fi

      if [[ "$line" == " "* && -n "$last_key" ]]; then
        value=$(trim_ws "$line")
        if [[ -n "$value" ]]; then
          current="${fields[$last_key]-}"
          if [[ "$current" != *"$value"* ]]; then
            fields["$last_key"]="${current:+$current }$value"
          fi
        fi
        continue
      fi

      [[ "$line" == *:* ]] || continue
      key=$(trim_ws "${line%%:*}")
      value=$(trim_ws "${line#*:}")

      if (( allowed_count > 0 )) && [[ -z "${allowed_fields[$key]+x}" ]]; then
        last_key=""
        continue
      fi

      nk=${key,,}
      nk=${nk//-/_}
      nk=${nk// /_}

      if [[ -n "${seen_keys[$nk]+x}" ]]; then
        fields["$nk"]="${fields[$nk]}${value:+ }$value"
      else
        fields["$nk"]="$value"
        seen_keys["$nk"]=1
        key_order+=("$nk")
      fi

      last_key="$nk"
      have_entry=1
    done <"$list_file"

    if (( have_entry )); then
      pkg="${fields[package]-}"
      installed_version="${installed_lookup[$pkg]-}"

      (( first_json )) || printf ',' >>"$tmp_file"
      first_json=0

      printf '{' >>"$tmp_file"
      local -i first_field=1
      for nk in "${key_order[@]}"; do
        (( first_field )) || printf ',' >>"$tmp_file"
        first_field=0
        printf '"%s":"%s"' "$(json_escape "$nk")" "$(json_escape "${fields[$nk]}")" >>"$tmp_file"
      done
      (( first_field )) || printf ',' >>"$tmp_file"
      printf '"installed_version":"%s","feed":"%s"' \
        "$(json_escape "$installed_version")" \
        "$(json_escape "$feed")" >>"$tmp_file"
      printf '}' >>"$tmp_file"
    fi
  done

  printf ']\n' >>"$tmp_file"

  mv "$tmp_file" "$output_file"
}

feed_list_files() {
  local out_list_name="$1"
  local refresh_feeds="${2:-0}"
  local -n out_list_ref="$out_list_name"

  out_list_ref=()

  if [[ "$refresh_feeds" == "1" || ! -f "$OPKG_FEEDS_JSON_CACHE_FILE" ]]; then
    create_json_feeds_list "$OPKG_FEEDS_FILE" "$OPKG_FEEDS_JSON_CACHE_FILE"
  fi

  if [[ ! -f "$OPKG_FEEDS_FILE" ]]; then
    return 0
  fi

  local line rest name
  while IFS= read -r line; do
    [[ "$line" == src/gz\ * ]] || continue
    rest=${line#src/gz }
    name=${rest%%[[:space:]]*}
    [[ -n "$name" ]] && out_list_ref+=("/usr/lib/opkg/lists/$name")
  done <"$OPKG_FEEDS_FILE"
}

cache_update_code() {
  local all_feeds_list_name="$1"
  local -n all_feeds_list="$all_feeds_list_name"
  local update_code=$CACHE_UP_TO_DATE
  local feed_cache_mtime feed_file_mtime cache_mtime path_mtime latest_mtime=0

  if [[ ! -f "$OPKG_FEEDS_JSON_CACHE_FILE" ]]; then
    update_code=$(( update_code | CACHE_UPDATE_FEEDS ))
  elif [[ -f "$OPKG_FEEDS_FILE" ]]; then
    feed_cache_mtime=$(get_mtime "$OPKG_FEEDS_JSON_CACHE_FILE") || feed_cache_mtime=""
    feed_file_mtime=$(get_mtime "$OPKG_FEEDS_FILE") || feed_file_mtime=""
    if [[ -z "$feed_cache_mtime" || -z "$feed_file_mtime" || "$feed_cache_mtime" -lt "$feed_file_mtime" ]]; then
      update_code=$(( update_code | CACHE_UPDATE_FEEDS ))
    fi
  fi

  if [[ ! -f "$OPKG_ALL_PACKAGES_JSON_CACHE_FILE" ]]; then
    update_code=$(( update_code | CACHE_UPDATE_ALL_PACKAGES ))
  else
    cache_mtime=$(get_mtime "$OPKG_ALL_PACKAGES_JSON_CACHE_FILE") || cache_mtime=""
    if [[ -z "$cache_mtime" ]]; then
      echo $(( update_code | CACHE_UPDATE_ALL_PACKAGES ))
      return 0
    fi

    local path
    for path in "$OPKG_FEEDS_FILE" "$OPKG_FEEDS_JSON_CACHE_FILE" "/usr/lib/opkg/status"; do
      if [[ -f "$path" ]]; then
        path_mtime=$(get_mtime "$path") || {
          echo $(( update_code | CACHE_UPDATE_ALL_PACKAGES ))
          return 0
        }
        (( path_mtime > latest_mtime )) && latest_mtime=$path_mtime
      fi
    done

    if [[ ${#all_feeds_list[@]} -eq 0 ]]; then
      feed_list_files all_feeds_list 0
    fi

    for path in "${all_feeds_list[@]}"; do
      [[ -f "$path" ]] || {
        echo $(( update_code | CACHE_UPDATE_ALL_PACKAGES ))
        return 0
      }
      path_mtime=$(get_mtime "$path") || {
        echo $(( update_code | CACHE_UPDATE_ALL_PACKAGES ))
        return 0
      }
      (( path_mtime > latest_mtime )) && latest_mtime=$path_mtime
    done

    if (( cache_mtime < latest_mtime )); then
      update_code=$(( update_code | CACHE_UPDATE_ALL_PACKAGES ))
    fi
  fi

  if (( (update_code & CACHE_UPDATE_FEEDS) != 0 )); then
    update_code=$(( update_code | CACHE_UPDATE_ALL_PACKAGES ))
  fi

  echo "$update_code"
}

createFeeds_Json() {
  local -a all_feeds_list=()
  feed_list_files all_feeds_list 0
  local update_code
  update_code=$(cache_update_code all_feeds_list)
  if (( update_code == CACHE_UP_TO_DATE )); then
    return 0
  fi
  if (( (update_code & CACHE_UPDATE_FEEDS) != 0 )); then
    feed_list_files all_feeds_list 1
  fi
  return 0
}

createPackages_Json() {
  local force_refresh="${1:-0}"
  local -a all_feeds_list=()
  feed_list_files all_feeds_list "$force_refresh"

  local update_code
  update_code=$(cache_update_code all_feeds_list)
  if (( update_code == CACHE_UP_TO_DATE )) && [[ "$force_refresh" != "1" ]]; then
    echo "createPackages_Json:CACHE_UP_TO_DATE"
    return 0
  fi

  if [[ "$force_refresh" == "1" ]] || (( (update_code & CACHE_UPDATE_FEEDS) != 0 )); then
    feed_list_files all_feeds_list 1
  fi

  local -a fields_list=("Package" "Description" "Version" "Size")
  map_opkg_list_files_to_json "$OPKG_ALL_PACKAGES_JSON_CACHE_FILE" fields_list all_feeds_list
  return 0
}

list_packages() {
  local force_refresh="${1:-0}"

  ensure_feed_config
  if [[ "$force_refresh" == "1" ]]; then
    update_packages || return $?
  fi

  createPackages_Json "$force_refresh"

  if [[ ! -f "$OPKG_ALL_PACKAGES_JSON_CACHE_FILE" ]]; then
    echo "Package JSON cache was not created" >&2
    return 1
  fi

  return 0
}

main() {
  if [[ $# -lt 2 ]]; then
    echo "Invalid args: expected '<family> <action>'" >&2
    return 1
  fi

  local family="$1"
  local action="$2"

  if [[ "$family" == "feed" && "$action" == "list" ]]; then
    create_json_feeds_list "$OPKG_FEEDS_FILE" "$OPKG_FEEDS_JSON_CACHE_FILE"
    return 0
  fi

  if [[ "$family" == "package" && "$action" == "list" ]]; then
    local force_refresh=0
    [[ "${3:-}" == "update" ]] && force_refresh=1
    list_packages "$force_refresh"
    return $?
  fi

  return 0
}

main "$@"

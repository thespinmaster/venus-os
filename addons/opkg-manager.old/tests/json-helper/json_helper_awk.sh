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
 
create_installed_lookup_file() {
  local lookup_file="$1"
  : >"$lookup_file"
  [[ -f /usr/lib/opkg/status ]] || return 0

  awk '
    function flush() {
      if (pkg != "" && status ~ /(^|[[:space:]])installed([[:space:]]|$)/) {
        print pkg "\t" ver
      }
      pkg=""; ver=""; status=""
    }
    /^$/ { flush(); next }
    /^Package:[[:space:]]*/ { sub(/^Package:[[:space:]]*/, ""); pkg=$0; next }
    /^Version:[[:space:]]*/ { sub(/^Version:[[:space:]]*/, ""); ver=$0; next }
    /^Status:[[:space:]]*/ { sub(/^Status:[[:space:]]*/, ""); status=$0; next }
    END { flush() }
  ' /usr/lib/opkg/status >"$lookup_file"
}

map_opkg_list_files_to_json() {
  local output_file="$1"
  local allowed_fields_csv="$2"
  shift 2

  local -a list_files=("$@")
  local lookup_file
  lookup_file=$(mktemp)
  create_installed_lookup_file "$lookup_file"

  mkdir -p "$(dirname "$output_file")"
  local tmp_file
  tmp_file=$(mktemp)

  awk -v OFS="" -v allowed_csv="$allowed_fields_csv" -v lookup_file="$lookup_file" '
    BEGIN {
      split(allowed_csv, af, ",")
      for (i in af) {
        if (af[i] != "") {
          allowed[af[i]] = 1
        }
      }
      while ((getline line < lookup_file) > 0) {
        split(line, p, "\t")
        installed[p[1]] = p[2]
      }
      close(lookup_file)
      first = 1
      print "["
    }
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    function norm_key(k) {
      k = tolower(k)
      gsub(/-/, "_", k)
      gsub(/ /, "_", k)
      return k
    }
    function esc(s) {
      gsub(/\\/, "\\\\", s)
      gsub(/\"/, "\\\"", s)
      gsub(/\r/, "\\r", s)
      gsub(/\t/, "\\t", s)
      gsub(/\n/, "\\n", s)
      return s
    }
    function flush_entry(   k, pkg, iv, out) {
      if (!have_entry) {
        return
      }
      pkg = fields["package"]
      iv = ""
      if (pkg in installed) {
        iv = installed[pkg]
      }
      fields["installed_version"] = iv
      fields["feed"] = feed

      out = "{"
      sep = ""
      for (k in fields) {
        out = out sep "\"" k "\":\"" esc(fields[k]) "\""
        sep = ","
      }
      out = out "}"

      if (!first) {
        print ","
      }
      print out
      first = 0

      delete fields
      delete seen
      have_entry = 0
      last_key = ""
    }
    FNR == 1 {
      flush_entry()
      split(FILENAME, parts, "/")
      feed = parts[length(parts)]
      delete fields
      delete seen
      have_entry = 0
      last_key = ""
    }
    /^$/ {
      flush_entry()
      next
    }
    {
      if ($0 ~ /^ / && last_key != "") {
        v = trim($0)
        if (v != "" && index(fields[last_key], v) == 0) {
          fields[last_key] = fields[last_key] " " v
        }
        next
      }

      c = index($0, ":")
      if (c == 0) {
        next
      }

      key = trim(substr($0, 1, c - 1))
      val = trim(substr($0, c + 1))

      if (length(allowed) > 0 && !(key in allowed)) {
        last_key = ""
        next
      }

      nk = norm_key(key)
      if (!(nk in seen)) {
        fields[nk] = val
        seen[nk] = 1
      } else {
        fields[nk] = fields[nk] " " val
      }
      last_key = nk
      have_entry = 1
    }
    END {
      flush_entry()
      print "]"
    }
  ' "${list_files[@]}" >"$tmp_file"

  mv "$tmp_file" "$output_file"
  rm -f "$lookup_file"
}

feed_list_files() {
  local refresh_feeds="${1:-0}"
  if [[ "$refresh_feeds" == "1" || ! -f "$OPKG_FEEDS_JSON_CACHE_FILE" ]]; then
    create_json_feeds_list "$OPKG_FEEDS_FILE" "$OPKG_FEEDS_JSON_CACHE_FILE"
  fi

  if [[ ! -f "$OPKG_FEEDS_FILE" ]]; then
    return 0
  fi

  awk '
    /^src\/gz[[:space:]]+/ {
      name=$2
      if (name != "") {
        print "/usr/lib/opkg/lists/" name
      }
    }
  ' "$OPKG_FEEDS_FILE"
}

cache_update_code() {
  local -a all_feeds_list=("$@")
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
      mapfile -t all_feeds_list < <(feed_list_files 0)
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
  mapfile -t all_feeds_list < <(feed_list_files 0)
  local update_code
  update_code=$(cache_update_code "${all_feeds_list[@]}")
  if (( update_code == CACHE_UP_TO_DATE )); then
    return 0
  fi
  if (( (update_code & CACHE_UPDATE_FEEDS) != 0 )); then
    mapfile -t all_feeds_list < <(feed_list_files 1)
  fi
  return 0
}

createPackages_Json() {
  local force_refresh="${1:-0}"
  local -a all_feeds_list=()
  mapfile -t all_feeds_list < <(feed_list_files "$force_refresh")

  local update_code
  update_code=$(cache_update_code "${all_feeds_list[@]}")
  if (( update_code == CACHE_UP_TO_DATE )) && [[ "$force_refresh" != "1" ]]; then
    echo "createPackages_Json:CACHE_UP_TO_DATE"
    return 0
  fi

  if [[ "$force_refresh" == "1" ]] || (( (update_code & CACHE_UPDATE_FEEDS) != 0 )); then
    mapfile -t all_feeds_list < <(feed_list_files 1)
  fi

  local fields_list="Package,Description,Version,Size"
  map_opkg_list_files_to_json "$OPKG_ALL_PACKAGES_JSON_CACHE_FILE" "$fields_list" "${all_feeds_list[@]}"
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

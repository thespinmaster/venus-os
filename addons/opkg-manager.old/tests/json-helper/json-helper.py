"""
Ported bash helper functions for opkg-manager and serial-device-installer.

These functions are Python ports of core bash helper logic for:
- JSON feed parsing and caching
- USB properties formatting
- Process stability probing

Original bash sources:
- opkg:180-220 (opkg_create_json_feeds_list)
- serial-device-installer:22-38 (__sdi_send_props_as_json)
- serial-device-installer:357-453 (sdi_get_stable_tty_process_pid)
"""

import json
import os
import re
import subprocess          
import sys
import tempfile
import time
from typing import Any, Dict, List, Optional, Set, Tuple

QML_FILE_SERVER_DIR="/tmp/opkg-manager"
OPKG_FEEDS_JSON_CACHE_FILE=f"{QML_FILE_SERVER_DIR}/feeds.json"
OPKG_ALL_PACKAGES_JSON_CACHE_FILE=f"{QML_FILE_SERVER_DIR}/packages.json"
OPKG_FEEDS_FILE="/etc/opkg/opkg-manager.conf"

CACHE_UP_TO_DATE = 0
CACHE_UPDATE_FEEDS = 1
CACHE_UPDATE_ALL_PACKAGES = 2


def ensure_feed_config(feed_type: str = "release") -> None:
    source = f"/data/conf/opkg-manager-{feed_type}.conf"

    if os.path.islink(OPKG_FEEDS_FILE) and os.path.exists(source):
        return

    if os.path.exists(source):
        os.symlink(source, OPKG_FEEDS_FILE, target_is_directory=False)
 
def update_packages() -> int:
    result = _run_subprocess(["opkg", "update"], timeout=60.0)
    if result is None:
        return 1
    return int(result.returncode)


def _get_mtime(path: str) -> Optional[float]:
    try:
        return os.path.getmtime(path)
    except Exception:
        return None


def _run_subprocess(
    command: List[str],
    timeout: float = 2.0,
) -> Optional[subprocess.CompletedProcess[str]]:
    try:
        return subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except Exception:
        return None

def create_json_feeds_list(feeds_file: str, cache_file: str, manager_feed_name: str = "opkg-manager") -> Optional[str]:
    """
    Port of opkg:180-220 - opkg_create_json_feeds_list()
    
    Parses feed config file and creates JSON list of feeds with caching.
    
    Args:
        feeds_file: Path to opkg feed config file (e.g., /etc/opkg/opkg-manager.conf)
        cache_file: Path to cache the JSON result
        manager_feed_name: Name of the manager's own feed (e.g., "opkg-manager")
    
    Returns:
        JSON string or None on error.
    
    The JSON format is: [{"name": "...", "url": "...", "builtin": true/false}, ...]
    Cache validity is checked using file mtime.
    """
    try:
        # Check cache validity using mtime
        if os.path.isfile(cache_file) and os.path.isfile(feeds_file):
            feeds_mtime = _get_mtime(feeds_file)
            cache_mtime = _get_mtime(cache_file)
            if feeds_mtime is not None and cache_mtime is not None and cache_mtime >= feeds_mtime:
                return

        feeds = []
        if os.path.isfile(feeds_file):
            with open(feeds_file, "r") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#") or not line.startswith("src/gz "):
                        continue
                    
                    # Parse: src/gz <name> <url>
                    parts = line.split(None, 3)  # Split on whitespace, max 4 parts
                    if len(parts) >= 3:
                        feeds.append({
                            "name": parts[1],
                            "url":  parts[2],
                            "builtin": parts[1] == manager_feed_name
                        })

        # Write cache
        _write_json_file(cache_file, feeds)
 
    except Exception as err:
        print(f"Error creating feeds list: {err}", file=sys.stderr)
        return None
 
 
def map_opkg_list_files_to_json(
    list_files: List[str],
    output_file: str,
    allowed_fields: Optional[List[str]] = None
):
    """
    Parse and combine multiple opkg stanza files into one JSON array.

    Args:
        list_files: Input opkg list file paths.
        output_file: Optional output path. If provided, combined JSON is written.
        allowed_fields: Optional list of field names to include. If provided, only
                   matching stanza fields are included in the output. Matching is
                   exact and case-sensitive against the original field names in the
                   list/status files (e.g. "Package", "Version", "Size").
    """
    try:
        allowed_field_set: Optional[Set[str]] = None
        if allowed_fields is not None:
            allowed_field_set = set(allowed_fields)

        combined: List[Dict[str, Any]] = []
        for path in list_files:
            combined.extend(_parse_opkg_stanza_file(path, allowed_field_set))

        _write_json_file(output_file, combined)
 
    except Exception as err:
        print(f"Error mapping opkg files to JSON: {err}", file=sys.stderr)

def _parse_opkg_stanza_file(list_file: str, allowed_fields: Optional[Set[str]] = None) -> List[Dict[str, Any]]:
    entries: List[Dict[str, Any]] = []
    current: Dict[str, Any] = {}
    last_key = ""
    feed = os.path.basename(list_file)

    def flush_entry() -> None:
        nonlocal current, last_key
        if current:
            current["feed"] = feed # bit of a hack :(
            entries.append(current)
        current = {}
        last_key = ""

    with open(list_file, "r", encoding="utf-8", errors="replace") as file_obj:
        for raw_line in file_obj:
            line = raw_line.rstrip("\n")

            if line == "":
                flush_entry()
                continue

            if line.startswith(" ") and last_key:
                # Avoid duplicating multiline fields like Description
                if isinstance(current[last_key], str):
                    new_value = line.strip()
                    if new_value not in current[last_key]:
                        current[last_key] = f"{current[last_key]} {new_value}".strip()
                continue

            if ":" not in line:
                continue

            key, value = line.split(":", 1)
            key = key.strip()
            # Skip field if it's not in allowed_fields
            if allowed_fields is not None and key not in allowed_fields:
                last_key = ""
                continue

            normalized_key = key.lower().replace("-", "_").replace(" ", "_")
            value = value.strip()

            if normalized_key in current:
                existing = current[normalized_key]
                if isinstance(existing, list):
                    existing.append(value)
                else:
                    current[normalized_key] = [existing, value]
            else:
                current[normalized_key] = value

            last_key = normalized_key

    flush_entry()
    return entries

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def create_installed_package_lookup():
    
    fd, tmp_path = tempfile.mkstemp(suffix=".json")
    os.close(fd)
    
    fields_list = ["Package", "Version", "Status"]
    map_opkg_list_files_to_json(["/usr/lib/opkg/status"], tmp_path, fields_list)
    status = load_json(tmp_path)
    os.unlink(tmp_path)

    status_by_package = {}
    for row in status:
        name = row.get("package")
        if not name:
            continue
        st = row.get("status", "")
        if "installed" not in st.split():
            continue
        status_by_package[name] = row.get("version", "")
    
    return status_by_package
 

def _write_json_file(file: str, payload: List[Dict[str, Any]]) -> None:
    os.makedirs(os.path.dirname(file), exist_ok=True)
    with open(file, "w", encoding="utf-8") as file_obj:
        json.dump(payload, file_obj, ensure_ascii=False)
        file_obj.write("\n")

def _cache_update_code(all_feeds_list: Optional[List[str]] = None) -> int:
    update_code = CACHE_UP_TO_DATE

    # Feed cache validity (same dependency as create_json_feeds_list).
    if not os.path.isfile(OPKG_FEEDS_JSON_CACHE_FILE):
        update_code |= CACHE_UPDATE_FEEDS
    elif os.path.isfile(OPKG_FEEDS_FILE):
        feed_cache_mtime = _get_mtime(OPKG_FEEDS_JSON_CACHE_FILE)
        feed_file_mtime = _get_mtime(OPKG_FEEDS_FILE)
        if feed_cache_mtime is None or feed_file_mtime is None:
            update_code |= CACHE_UPDATE_FEEDS
        elif feed_cache_mtime < feed_file_mtime:
            update_code |= CACHE_UPDATE_FEEDS

    # Packages cache depends on feeds cache and list/status files.
    if not os.path.isfile(OPKG_ALL_PACKAGES_JSON_CACHE_FILE):
        update_code |= CACHE_UPDATE_ALL_PACKAGES
    else:
        cache_mtime = _get_mtime(OPKG_ALL_PACKAGES_JSON_CACHE_FILE)
        if cache_mtime is None:
            return update_code | CACHE_UPDATE_ALL_PACKAGES

        latest_mtime = 0.0
        for path in (OPKG_FEEDS_FILE, OPKG_FEEDS_JSON_CACHE_FILE, "/usr/lib/opkg/status"):
            if os.path.isfile(path):
                path_mtime = _get_mtime(path)
                if path_mtime is None:
                    return update_code | CACHE_UPDATE_ALL_PACKAGES
                latest_mtime = max(latest_mtime, path_mtime)

        if all_feeds_list is None:
            all_feeds_list = _feed_list_files(refresh_feeds=False)

        for list_file in all_feeds_list:
            if not os.path.isfile(list_file):
                return update_code | CACHE_UPDATE_ALL_PACKAGES
            list_mtime = _get_mtime(list_file)
            if list_mtime is None:
                return update_code | CACHE_UPDATE_ALL_PACKAGES
            latest_mtime = max(latest_mtime, list_mtime)

        if cache_mtime < latest_mtime:
            update_code |= CACHE_UPDATE_ALL_PACKAGES

    # If feeds are stale/missing, packages are also stale by dependency.
    if update_code & CACHE_UPDATE_FEEDS:
        update_code |= CACHE_UPDATE_ALL_PACKAGES

    return update_code
 
def _feed_list_files(refresh_feeds: bool = False):
    if refresh_feeds or not os.path.isfile(OPKG_FEEDS_JSON_CACHE_FILE):
        create_json_feeds_list(OPKG_FEEDS_FILE, OPKG_FEEDS_JSON_CACHE_FILE)

    all_feeds_json = load_json(OPKG_FEEDS_JSON_CACHE_FILE)
    list_files = []
    for row in all_feeds_json:
        name=row.get("name")
        if name:
            list_files.append(f"/usr/lib/opkg/lists/{name}")

    return list_files

def createFeeds_Json():
    all_feeds_list = _feed_list_files(refresh_feeds=False)
    update_code = _cache_update_code(all_feeds_list)
    if update_code == CACHE_UP_TO_DATE:
        return
    if update_code & CACHE_UPDATE_FEEDS:
        all_feeds_list = _feed_list_files(refresh_feeds=True)

def createPackages_Json(force_refresh: bool = False):

    all_feeds_list = _feed_list_files(refresh_feeds=force_refresh)
    update_code = _cache_update_code(all_feeds_list)
    if update_code == CACHE_UP_TO_DATE and not force_refresh:
        print("createPackages_Json:CACHE_UP_TO_DATE")
        return
    
    if force_refresh or update_code & CACHE_UPDATE_FEEDS:
        all_feeds_list = _feed_list_files(refresh_feeds=True)

    fields_list = ["Package", "Description", "Version", "Size"]
    map_opkg_list_files_to_json(all_feeds_list, OPKG_ALL_PACKAGES_JSON_CACHE_FILE, fields_list)
 
    all_packages_json = load_json(OPKG_ALL_PACKAGES_JSON_CACHE_FILE)
    print("load_json:all_packages_json 1")

    if all_packages_json:
        print("load_json:all_packages_json 2")
        status_by_package_json = create_installed_package_lookup()

        for pkg in all_packages_json:
            name = pkg.get("package") # or pkg.get("name")
            pkg["installed_version"] = status_by_package_json.get(name, "")

    _write_json_file(OPKG_ALL_PACKAGES_JSON_CACHE_FILE, all_packages_json)

    return update_code



def list_packages(force_refresh) -> int:

    ensure_feed_config()

    if force_refresh:
        status = update_packages()
        if status != 0:
            return status

    createPackages_Json(force_refresh=force_refresh)

    if not os.path.isfile(OPKG_ALL_PACKAGES_JSON_CACHE_FILE):
        print("Package JSON cache was not created", file=sys.stderr)
        return 1

    return 0
 
def main() -> int:
 
    print("in python main")
    if len(sys.argv) < 3:
        raise Exception("Invalid args: expected '<family> <action>'")

    family = sys.argv[1]
    action = sys.argv[2]

    try:
        if family == "feed" and action == "list":
            create_json_feeds_list(OPKG_FEEDS_FILE, OPKG_FEEDS_JSON_CACHE_FILE)
            return 0
        if family == "package" and action == "list":
            force_refresh = len(sys.argv) > 3 and sys.argv[3] == "update"
            return list_packages(force_refresh)
        
        return 0
    except Exception as err:
        print(f"Error creating package JSON cache: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())


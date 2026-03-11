#!/bin/bash
# cleanup-vscode-server.sh
# Removes all but the latest VS Code server install from ~/.vscode-server/bin
# Usage: ./cleanup-vscode-server.sh [--dry-run]

set -euo pipefail

VSCODE_SERVER_DIR="$HOME/.vscode-server"
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
    echo "[DRY RUN] No files will be deleted."
fi

if [[ ! -d "$VSCODE_SERVER_DIR" ]]; then
    echo "VS Code server directory not found: $VSCODE_SERVER_DIR"
    exit 1
fi


cd "$VSCODE_SERVER_DIR"

# List all code-* files (VS Code server binaries)
shopt -s nullglob
code_files=(code-*)
shopt -u nullglob

if [[ ${#code_files[@]} -eq 0 ]]; then
    echo "No VS Code server installs found (no code-* files)."
    exit 0
fi

if [[ ${#code_files[@]} -le 1 ]]; then
    echo "Nothing to clean up. Found ${#code_files[@]} VS Code server install(s)."
    exit 0
fi

 # The first file is the latest (by mtime)
latest_file="${code_files[0]}"
echo "Latest VS Code server install: $latest_file"

# Build list of files to delete and calculate total size before deletion
files_to_delete=()
total_bytes=0
for file in "${code_files[@]}"; do
    if [[ "$file" != "$latest_file" ]]; then
        files_to_delete+=("$file")
        if [[ -f "$file" ]]; then
            size=$(stat -c %s "$file")
            total_bytes=$((total_bytes + size))
        fi
    fi
}

# Convert bytes to human-readable
if command -v numfmt >/dev/null 2>&1; then
    hr_size=$(numfmt --to=iec --suffix=B $total_bytes)
else
    hr_size="$total_bytes bytes"
fi

if [[ ${#files_to_delete[@]} -eq 0 ]]; then
    echo "Nothing to clean up. Only the latest VS Code server install exists."
    exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
    for file in "${files_to_delete[@]}"; do
        echo "[DRY RUN] Would remove: $VSCODE_SERVER_DIR/$file"
    done
    echo "[DRY RUN] Total space that would be freed: $hr_size ($total_bytes bytes)"
else
    for file in "${files_to_delete[@]}"; do
        echo "Removing: $VSCODE_SERVER_DIR/$file"
        rm -f -- "$VSCODE_SERVER_DIR/$file"
    done
    echo "Total space freed: $hr_size ($total_bytes bytes)"
fi

echo "Cleanup complete."

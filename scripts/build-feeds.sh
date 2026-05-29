#!/usr/bin/env bash
#####################################################
# Used by git hub actions to create the public feeds
# DO NOT MOVE OR RENAME
#####################################################

set -euo pipefail

echo "======================================="
echo "   Building opkg feeds"
echo "======================================="

# Ensure clean output directory
rm -rf feeds
mkdir -p feeds

echo "[1/3] Detecting build method..."

# ---------------------------------------
# 1. Python-based feed generation
# ---------------------------------------
if [ -f "generate_feeds.py" ]; then
    echo "→ Running generate_feeds.py"
    python3 generate_feeds.py
fi

if [ -f "build.py" ]; then
    echo "→ Running build.py"
    python3 build.py
fi

# ---------------------------------------
# 2. Makefile-based generation
# ---------------------------------------
if [ -f "Makefile" ]; then
    if grep -q "^feeds:" Makefile; then
        echo "→ Running make feeds"
        make feeds
    else
        echo "→ Makefile found but no 'feeds' target"
    fi
fi

# ---------------------------------------
# 3. Optional custom scripts directory
# ---------------------------------------
if [ -d "scripts" ]; then
    if [ -f "scripts/generate_feeds.sh" ]; then
        echo "→ Running scripts/generate_feeds.sh"
        bash scripts/generate_feeds.sh
    fi
fi

echo "[2/3] Validating output..."

if [ ! -d "feeds" ]; then
    echo "ERROR: feeds/ directory was not created"
    exit 1
fi

FEED_COUNT=$(find feeds -type f | wc -l | tr -d ' ')
echo "→ Feed files generated: $FEED_COUNT"

if [ "$FEED_COUNT" -eq 0 ]; then
    echo "WARNING: feeds/ is empty"
fi

echo "[3/3] Feed build complete"

# Optional debug output (helpful in CI)
echo "Sample output:"
find feeds -type f | head -20

echo "======================================="
echo "SUCCESS: opkg feeds built successfully"
echo "======================================="
#!/usr/bin/env bash
# OPTIONAL: Linux-native mirror when /mnt/c drvfs breaks. Syncs only app sources — NOT sibling clones.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_SRC="$("$SCRIPT_DIR/sync-linux-build-tree.sh")"

cd "$LINUX_SRC"
xtool dev build

echo "Build OK in $LINUX_SRC"
if [[ -d "$LINUX_SRC/xtool/BetterSEQTALearn.app" ]]; then
  echo "App bundle: $LINUX_SRC/xtool/BetterSEQTALearn.app"
fi

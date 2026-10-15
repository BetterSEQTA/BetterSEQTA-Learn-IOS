#!/usr/bin/env bash
# Minimal rsync of iOS app sources to ext4 (excludes Android/DesQTA siblings). Prints LINUX_SRC path.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=wsl-env.sh
source "$SCRIPT_DIR/wsl-env.sh"

WIN_SRC="${WIN_SRC:-/mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS}"
LINUX_SRC="${LINUX_SRC:-${HOME}/BetterSEQTA-Learn-IOS-build}"

RSYNC_EXCLUDES=(
  --exclude '.git/'
  --exclude '.build/'
  --exclude 'xtool/'
  --exclude '.swiftpm/'
  --exclude 'Secrets/'
  --exclude 'BetterSEQTA-Learn-Android/'
  --exclude 'BetterSEQTA-Teach-Android/'
  --exclude 'BetterSEQTA-Teach-IOS/'
  --exclude 'DesQTA/'
  --exclude 'node_modules/'
)

mkdir -p "$LINUX_SRC"
rsync -a --delete "${RSYNC_EXCLUDES[@]}" "$WIN_SRC/" "$LINUX_SRC/"
printf '%s\n' "$LINUX_SRC"

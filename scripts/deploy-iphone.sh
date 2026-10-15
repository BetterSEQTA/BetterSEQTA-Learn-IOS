#!/usr/bin/env bash
# Build on WSL ext4 (avoids drvfs .app copy failure) and install to USB device via xtool.
# Default: xtool.device.yml (no widget appex) — widget embed hits LoadCommands signing limit on WSL.
# Set WITH_WIDGET=1 to use full xtool.yml (may fail signing until xtool/Apple toolchain fix).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=wsl-env.sh
source "$SCRIPT_DIR/wsl-env.sh"

BUNDLE_ID="org.betterseqta.learn"
# --usb (default), --network (Wi‑Fi debugging), or --all
USB_FLAG="${INSTALL_TRANSPORT:-${1:---usb}}"

if ! command -v zip >/dev/null 2>&1; then
  echo "[deploy-iphone] 'zip' is required for xtool install packaging."
  echo "  sudo apt-get update && sudo apt-get install -y zip"
  exit 1
fi

echo "[deploy-iphone] Syncing sources to Linux build tree (no Android/DesQTA)…"
LINUX_SRC="$("$SCRIPT_DIR/sync-linux-build-tree.sh")"
cd "$LINUX_SRC"
rm -f .build/.lock 2>/dev/null || true
# Package platform / target graph changes are not always picked up incrementally.
rm -rf .build

if [[ "${WITH_WIDGET:-0}" == "1" ]]; then
  echo "[deploy-iphone] Building with widget extension (xtool.yml)."
else
  if [[ ! -f xtool.device.yml ]]; then
    echo "[deploy-iphone] Missing xtool.device.yml in repo."
    exit 1
  fi
  cp xtool.device.yml xtool.yml
  echo "[deploy-iphone] Building without widget (xtool.device.yml) for device signing."
fi

# Drop stale appex bundle from prior widget builds.
rm -rf xtool/BetterSEQTALearn.app

echo "[deploy-iphone] Building at $LINUX_SRC …"
set +e
BUILD_OUT="$(mktemp)"
xtool dev build 2>&1 | tee "$BUILD_OUT"
set -e

if ! grep -q 'Build complete!' "$BUILD_OUT"; then
  echo "[deploy-iphone] Build failed — see log above."
  exit 1
fi

if grep -q 'Signing failed' "$BUILD_OUT"; then
  echo "[deploy-iphone] Warning: post-build signing reported failure (install may still sign)."
fi

APP="$LINUX_SRC/xtool/BetterSEQTALearn.app"
if [[ ! -d "$APP" ]]; then
  APP="$(grep -oE 'NSFilePath=/home/[^,}]+BetterSEQTALearn\.app' "$BUILD_OUT" | head -1 | sed 's/NSFilePath=//' || true)"
fi
if [[ -z "$APP" || ! -d "$APP" ]]; then
  APP="$(find "$HOME/.cache/xtool" -type d -name 'BetterSEQTALearn.app' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-)"
fi

if [[ -z "$APP" || ! -d "$APP" ]]; then
  echo "[deploy-iphone] Could not locate BetterSEQTALearn.app after build."
  echo "Expected: $LINUX_SRC/xtool/BetterSEQTALearn.app"
  exit 1
fi

if [[ -d "$APP/PlugIns/LearnWidget.appex" ]] && [[ "${WITH_WIDGET:-0}" != "1" ]]; then
  echo "[deploy-iphone] Removing embedded widget before install (signing workaround)."
  rm -rf "$APP/PlugIns"
fi

echo "[deploy-iphone] Checking device ($USB_FLAG)…"
set +e
DEV_OUT="$(xtool devices 2>&1)"
DEV_STATUS=$?
set -e
echo "$DEV_OUT"
if echo "$DEV_OUT" | grep -qiE 'muxError|LockdownClient'; then
  echo "[deploy-iphone] WSL cannot talk to the iPhone over USB (usbmux lockdown)."
  echo "  1. Windows: .\\scripts\\attach-iphone-usb.ps1 (UAC if needed)"
  echo "  2. Unplug/replug cable; unlock iPhone; Settings → Privacy & Security → Developer Mode ON"
  echo "  3. wsl -d Ubuntu-24.04 -- xtool devices   (must list your phone, no muxError)"
  echo "  Or Wi‑Fi: enable device pairing in Xcode/Settings, then INSTALL_TRANSPORT=--network ./scripts/deploy-iphone.sh"
  exit 1
fi
if [[ $DEV_STATUS -ne 0 ]] && ! echo "$DEV_OUT" | grep -qi 'iPhone'; then
  echo "[deploy-iphone] No device visible. Fix USB attach or use INSTALL_TRANSPORT=--network."
  exit 1
fi

echo "[deploy-iphone] Installing: $APP"
echo "[deploy-iphone] Phases: Unpack → Provision → Sign → Package → Connect (push to phone). Connect can take 1–3 min; hang = USB mux."
if ! xtool install "$USB_FLAG" "$APP"; then
  echo "[deploy-iphone] Install failed."
  echo "  Signing: use default deploy (no widget). Certs: revoke stale dev certs if xtool asked."
  echo "  Connect hang: pkill -f 'xtool install' in WSL, re-run attach-iphone-usb.ps1, retry."
  exit 1
fi

echo "[deploy-iphone] Launching $BUNDLE_ID"
xtool launch "$USB_FLAG" "$BUNDLE_ID"
echo "[deploy-iphone] Done."

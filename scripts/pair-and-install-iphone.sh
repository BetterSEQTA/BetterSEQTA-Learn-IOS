#!/usr/bin/env bash
# Pair iPhone over USB on native Linux, then install the last xtool build.
set -euo pipefail

export PATH="${HOME}/.local/bin:${HOME}/.local/share/swift/usr/bin:${PATH}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${APP:-${HOME}/BetterSEQTA-Learn-IOS-build/xtool/BetterSEQTALearn.app}"
BUNDLE_ID="org.betterseqta.learn"

echo "=== iPhone USB pairing + install ==="
echo "On the iPhone: unlocked, Developer Mode ON (Settings → Privacy & Security → Developer Mode), tap Trust if prompted."
echo ""

# GNOME GVFS often steals the USB imaging interface before usbmuxd can pair.
pkill -u "$(id -un)" -f 'gvfsd-afc|gvfs-afc-volume-monitor|gvfsd-gphoto2|gvfs-gphoto2-volume-monitor' 2>/dev/null || true

if command -v systemctl >/dev/null 2>&1; then
  echo "Restarting usbmuxd (sudo)…"
  sudo systemctl restart usbmuxd.service
  sleep 2
fi

echo "Clearing stale pairing (ignore errors)…"
idevicepair unpair 2>/dev/null || true

echo "Pairing — confirm Trust on the phone if asked…"
if ! idevicepair pair; then
  echo ""
  echo "Pairing failed. Unplug/replug the cable (direct USB port), unlock the phone, then run this script again."
  journalctl -u usbmuxd -n 15 --no-pager 2>/dev/null || true
  exit 1
fi

echo ""
ideviceinfo -k DeviceName -k ProductVersion 2>/dev/null || ideviceinfo | head -10

if [[ ! -d "$APP" ]]; then
  echo "App bundle missing: $APP"
  echo "Build first: WIN_SRC=\"$SCRIPT_DIR/..\" bash \"$SCRIPT_DIR/deploy-iphone.sh\""
  exit 1
fi

echo ""
echo "Installing $APP …"
xtool install --usb "$APP"
echo "Launching $BUNDLE_ID …"
xtool launch --usb "$BUNDLE_ID"
echo "Done."

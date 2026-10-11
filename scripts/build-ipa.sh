#!/usr/bin/env bash
# Build a signed .ipa on WSL ext4 (xtool.device.yml, no widget appex).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=wsl-env.sh
source "$SCRIPT_DIR/wsl-env.sh"

WIN_REPO="/mnt/c/Users/Aden/Documents/BetterSEQTA-Learn-IOS"
OUT_DIR="${OUT_DIR:-/mnt/c/Users/Aden/Downloads}"
IPA_NAME="${IPA_NAME:-BetterSEQTALearn.ipa}"

if ! command -v zip >/dev/null 2>&1; then
  echo "[build-ipa] Install zip in WSL: sudo apt-get install -y zip unzip"
  exit 1
fi

echo "[build-ipa] Syncing sources to Linux build tree…"
LINUX_SRC="$("$SCRIPT_DIR/sync-linux-build-tree.sh")"
cd "$LINUX_SRC"
rm -f .build/.lock 2>/dev/null || true

if [[ "${WITH_WIDGET:-0}" == "1" ]]; then
  echo "[build-ipa] Using full xtool.yml (widget; may fail signing on WSL)."
else
  cp xtool.device.yml xtool.yml
  echo "[build-ipa] Using xtool.device.yml (no widget)."
fi

echo "[build-ipa] Building IPA…"
set +e
BUILD_OUT="$(mktemp)"
xtool dev build --ipa 2>&1 | tee "$BUILD_OUT"
set -e

if ! grep -q 'Build complete!' "$BUILD_OUT"; then
  echo "[build-ipa] Build failed."
  exit 1
fi

LINUX_IPA="$LINUX_SRC/xtool/BetterSEQTALearn.ipa"
if [[ ! -f "$LINUX_IPA" ]]; then
  LINUX_IPA="$(grep -oE '/home/[^[:space:]]+BetterSEQTALearn\.ipa' "$BUILD_OUT" | tail -1 || true)"
fi
if [[ ! -f "$LINUX_IPA" ]]; then
  echo "[build-ipa] IPA not found under $LINUX_SRC/xtool/"
  exit 1
fi

mkdir -p "$OUT_DIR"
OUT_IPA="$OUT_DIR/$IPA_NAME"
cp -f "$LINUX_IPA" "$OUT_IPA"
echo "[build-ipa] Wrote: $OUT_IPA"
echo "[build-ipa] Linux copy: $LINUX_IPA"
ls -lh "$OUT_IPA"

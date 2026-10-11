#!/usr/bin/env bash
# Install xtool + dependencies on native Linux (Ubuntu 24.04 / Zorin 18 / Debian-based).
# Docs: https://xtool.sh/documentation/xtool/installation-linux/
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Installing apt packages (sudo required)..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    curl ca-certificates unzip usbmuxd libimobiledevice-utils \
    libfuse2t64 fuse3 xz-utils clang libicu-dev libcurl4-openssl-dev \
    libxml2-dev zlib1g-dev
  sudo systemctl enable --now usbmuxd.service || true
else
  apt-get update -qq
  apt-get install -y -qq \
    curl ca-certificates unzip usbmuxd libimobiledevice-utils \
    libfuse2t64 fuse3 xz-utils clang libicu-dev libcurl4-openssl-dev \
    libxml2-dev zlib1g-dev
  systemctl enable --now usbmuxd.service || true
fi

SWIFT_URL="https://download.swift.org/swift-6.4.0-release/ubuntu2404/swift-6.4.0-RELEASE/swift-6.4.0-RELEASE-ubuntu24.04.tar.gz"
SWIFT_DIR="${SWIFT_INSTALL_DIR:-$HOME/.local/share/swift-6.4.0-RELEASE-ubuntu24.04}"
SWIFT_LINK="${SWIFT_LINK_DIR:-$HOME/.local/share/swift}"

if ! command -v swift >/dev/null 2>&1 || ! swift --version 2>/dev/null | grep -q 'Swift version 6.4'; then
  echo "Downloading Swift 6.4..."
  curl -fL "$SWIFT_URL" -o /tmp/swift-6.4.0-ubuntu24.04.tar.gz
  mkdir -p "$(dirname "$SWIFT_DIR")"
  rm -rf "$SWIFT_DIR"
  tar -xzf /tmp/swift-6.4.0-ubuntu24.04.tar.gz -C "$(dirname "$SWIFT_DIR")"
  ln -sfn "$SWIFT_DIR" "$SWIFT_LINK"
fi

export PATH="$SWIFT_LINK/usr/bin:${PATH:-}"

XT_BIN="${XT_BIN:-$HOME/.local/bin/xtool}"
if ! command -v xtool >/dev/null 2>&1; then
  mkdir -p "$(dirname "$XT_BIN")"
  curl -fL "https://github.com/xtool-org/xtool/releases/latest/download/xtool-$(uname -m).AppImage" \
    -o "$XT_BIN"
  chmod +x "$XT_BIN"
fi

echo ""
echo "=== Installed ==="
swift --version
xtool --version 2>/dev/null || xtool --help | head -3
usbmuxd --help 2>&1 | head -2
command -v ideviceinfo >/dev/null && ideviceinfo 2>/dev/null | head -5 || true

echo ""
echo "Add to shell if needed (install script also updates ~/.bashrc on first manual run):"
echo '  export PATH="$HOME/.local/bin:$HOME/.local/share/swift/usr/bin:$PATH"'
echo ""
echo "Next (interactive, requires Xcode XIP from Apple):"
echo "  xtool setup"
echo "  Download Xcode: https://developer.apple.com/download/all/?q=Xcode"

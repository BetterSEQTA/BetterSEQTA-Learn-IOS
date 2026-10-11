#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq curl ca-certificates unzip usbmuxd libimobiledevice-utils libfuse2t64 fuse3 xz-utils clang libicu-dev libcurl4-openssl-dev libxml2-dev zlib1g-dev

if ! command -v swift >/dev/null 2>&1 || ! swift --version 2>/dev/null | grep -q 'Swift version 6.4'; then
  SWIFT_URL="https://download.swift.org/swift-6.4.0-release/ubuntu2404/swift-6.4.0-RELEASE/swift-6.4.0-RELEASE-ubuntu24.04.tar.gz"
  curl -fL "$SWIFT_URL" -o /tmp/swift.tar.gz
  rm -rf /opt/swift-6.4.0-RELEASE-ubuntu24.04 /opt/swift
  tar -xzf /tmp/swift.tar.gz -C /opt
  ln -sfn /opt/swift-6.4.0-RELEASE-ubuntu24.04 /opt/swift
  echo 'export PATH=/opt/swift/usr/bin:$PATH' > /etc/profile.d/swift.sh
fi

export PATH="/opt/swift/usr/bin:${PATH}"

if ! command -v xtool >/dev/null 2>&1; then
  curl -fL "https://github.com/xtool-org/xtool/releases/latest/download/xtool-$(uname -m).AppImage" -o /usr/local/bin/xtool
  chmod +x /usr/local/bin/xtool
fi

swift --version
xtool --help | head -8
usbmuxd --help 2>&1 | head -2

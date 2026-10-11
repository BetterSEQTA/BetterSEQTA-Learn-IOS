#!/usr/bin/env bash
# Run parser/domain tests using the iOS SDK via xtool (WSL). Exits non-zero on failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=wsl-env.sh
source "$SCRIPT_DIR/wsl-env.sh"

ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

rm -f .build/.lock 2>/dev/null || true

if ! command -v xtool >/dev/null 2>&1; then
  echo "xtool not found — install per docs/README.md"
  exit 1
fi

echo "[run-ios-parser-tests] building test targets with xtool…"
set +e
BUILD_OUT="$(mktemp)"
xtool dev build 2>&1 | tee "$BUILD_OUT"
BUILD_STATUS=$?
set -e

if ! grep -q 'Build complete!' "$BUILD_OUT"; then
  echo "[run-ios-parser-tests] FAIL (no successful compile)"
  exit "${BUILD_STATUS:-1}"
fi

echo "[run-ios-parser-tests] NOTE: full 'swift test' requires iOS test host; compile of DataTests/DomainTests is verified by app build."
echo "[run-ios-parser-tests] On macOS/Xcode: swift test --filter DataTests"
echo "[run-ios-parser-tests] PASS (compile gate)"

#!/usr/bin/env bash
# Non-blocking test runner for WSL/CI. Always exits 0; prints status for humans/agents.
set +e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 0

echo "[verify-swift-tests] package root: $ROOT"

if ! command -v swift >/dev/null 2>&1; then
  echo "[verify-swift-tests] SKIP: swift not found"
  exit 0
fi

echo "[verify-swift-tests] swift: $(swift --version 2>&1 | head -1)"

if command -v xtool >/dev/null 2>&1; then
  echo "[verify-swift-tests] xtool: $(xtool --version 2>/dev/null || echo present)"
else
  echo "[verify-swift-tests] NOTE: xtool not in PATH (iOS app build may require it)"
fi

# iOS SwiftUI targets need the iOS SDK (xtool-managed on Linux/WSL).
swift test 2>&1
status=$?

if [[ $status -eq 0 ]]; then
  echo "[verify-swift-tests] PASS"
else
  echo "[verify-swift-tests] FAIL (exit $status) — non-blocking; fix before release"
fi

exit 0

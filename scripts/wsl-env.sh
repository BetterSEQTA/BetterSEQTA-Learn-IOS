# Source from other WSL scripts so `swift` is on PATH (non-interactive bash skips profile.d).
if [[ -f /etc/profile.d/swift.sh ]]; then
  # shellcheck source=/dev/null
  source /etc/profile.d/swift.sh
fi

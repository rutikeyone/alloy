#!/usr/bin/env bash
# Runs notes_app on an iOS simulator, booting one if none is running yet.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! xcrun simctl list devices booted | grep -q "(Booted)"; then
  target="$(xcrun simctl list devices available \
    | grep -oE 'iPhone [^(]*\([0-9A-F-]{36}\)' \
    | tail -1 \
    | grep -oE '[0-9A-F-]{36}')"
  if [ -z "$target" ]; then
    echo "No iOS simulator is available. Install one through Xcode first." >&2
    exit 1
  fi
  echo "Booting simulator $target ..."
  xcrun simctl boot "$target"
  open -a Simulator
fi

udid="$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)"

echo "Running on $udid"
flutter run -d "$udid" "$@"

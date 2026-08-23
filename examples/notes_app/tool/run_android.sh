#!/usr/bin/env bash
# Runs notes_app on an Android emulator, booting the first available AVD if
# none is running yet.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! flutter devices --machine | grep -q '"targetPlatform": *"android'; then
  avd="$(flutter emulators --machine | sed -n 's/.*"id": *"\([^"]*\)".*/\1/p' | head -1)"
  if [ -z "$avd" ]; then
    echo "No Android emulator is defined. Create one in Android Studio first." >&2
    exit 1
  fi
  echo "Booting emulator $avd ..."
  flutter emulators --launch "$avd"

  for _ in $(seq 1 60); do
    if flutter devices --machine | grep -q '"targetPlatform": *"android'; then break; fi
    sleep 2
  done
fi

device="$(flutter devices --machine \
  | tr '}' '\n' \
  | grep '"targetPlatform": *"android' \
  | sed -n 's/.*"id": *"\([^"]*\)".*/\1/p' \
  | head -1)"

echo "Running on $device"
flutter run -d "$device" "$@"

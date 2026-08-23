#!/usr/bin/env bash
# Regenerates the container and builds both platforms without signing, which is
# what CI needs to know the example still compiles everywhere.
set -euo pipefail

cd "$(dirname "$0")/.."

dart run build_runner build
flutter build apk --debug
flutter build ios --simulator --no-codesign

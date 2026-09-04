#!/usr/bin/env sh
# Renders assets/banner.svg to the PNG the READMEs show.
#
# A PNG rather than the SVG because pub.dev proxies images and is unreliable
# with SVG; the source stays beside it and this regenerates from it.
#
# Two flags carry the whole result and both are easy to leave off:
#
#   --default-background-color=00000000  keeps the alpha channel. Without it
#     Chrome paints the page white, and because the card is a rounded rect the
#     four corners come out white — which is invisible on a light background
#     and obvious on GitHub's dark one. This has been got wrong once already.
#
#   --force-device-scale-factor=2  with a window matching the SVG's own
#     1200x360 gives the 2400x720 the READMEs expect. Doubling the window
#     instead renders the SVG at 1:1 in the corner of a larger canvas.
set -e
cd "$(dirname "$0")/.."

CHROME=${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}
[ -x "$CHROME" ] || { echo "Set CHROME to a Chrome binary; $CHROME is not one."; exit 1; }

"$CHROME" --headless --disable-gpu \
  --force-device-scale-factor=2 \
  --default-background-color=00000000 \
  --hide-scrollbars \
  --window-size=1200,360 \
  --screenshot=assets/banner.png \
  "file://$PWD/assets/banner.svg" >/dev/null 2>&1

echo "assets/banner.png written"

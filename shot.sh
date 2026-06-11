#!/usr/bin/env bash
# Screenshot the built HTML with headless Chrome for CSS polishing.
# Usage: ./shot.sh [OUT_PNG] [HTML] [WIDTHxHEIGHT]
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNG="${1:-/tmp/gp-shot.png}"
HTML="${2:-$REPO_DIR/dist/graypaper.html}"
SIZE="${3:-1300,2400}"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars \
  --force-color-profile=srgb --default-background-color=FFFFFFFF \
  --screenshot="$PNG" --window-size="$SIZE" \
  "file://$HTML" >/dev/null 2>&1
echo "wrote $PNG"

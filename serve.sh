#!/usr/bin/env bash
# Serve the built Gray Paper HTML for deep-linking (default port 8722).
# Idempotent: if it's already up, just prints the URL.
set -euo pipefail
PORT="${1:-8722}"
DIST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dist"
URL="http://localhost:$PORT/graypaper.html"

if curl -s -o /dev/null --max-time 2 "$URL"; then
  echo "already serving: $URL"
  exit 0
fi
if [ ! -f "$DIST/graypaper.html" ]; then
  echo "no build yet — run ./build.sh first" >&2
  exit 1
fi
cd "$DIST"
nohup python3 -m http.server "$PORT" >/tmp/gp-server.log 2>&1 &
sleep 1
echo "serving: $URL"

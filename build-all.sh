#!/usr/bin/env bash
# Build every Gray Paper version into dist/<version>/ and wire up a version
# toggle across them. Edit VERSIONS / SRC below to add versions.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Versions, latest first (order shown in the selector). Each maps to a source checkout.
VERSIONS=(0.8.0 0.7.2)
declare -A SRC=(
  [0.8.0]="$HOME/dev/graypaper"
  [0.7.2]="$HOME/dev/graypaper-0.7.2"
)

for v in "${VERSIONS[@]}"; do
  echo "==== building v$v ===="
  "$REPO_DIR/build.sh" "${SRC[$v]}" "$REPO_DIR/dist/$v"
done

# Inject the cross-version selector once all builds exist.
for v in "${VERSIONS[@]}"; do
  python3 "$REPO_DIR/version_nav.py" "$REPO_DIR/dist/$v/graypaper.html" "$v" "${VERSIONS[@]}"
done

# Landing redirect to the latest version.
cat > "$REPO_DIR/dist/index.html" <<EOF
<!doctype html><meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=${VERSIONS[0]}/graypaper.html">
<a href="${VERSIONS[0]}/graypaper.html">Gray Paper v${VERSIONS[0]}</a>
EOF

echo ">> Done. Latest: dist/${VERSIONS[0]}/graypaper.html"

#!/usr/bin/env bash
#
# Build a light, single-column HTML + MathML render of the JAM Gray Paper
# from its LaTeX source, using LaTeXML and the local stub bindings.
#
# Usage:
#   ./build.sh [SRC_DIR] [OUT_DIR]
#     SRC_DIR  graypaper LaTeX source checkout   (default: ~/dev/graypaper)
#     OUT_DIR  output directory for the build     (default: ./dist)
#
# Prereqs:  brew install latexml
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${1:-$HOME/dev/graypaper}"
OUT="${2:-$REPO_DIR/dist}"

if ! command -v latexml >/dev/null 2>&1; then
  echo "error: latexml not found. Install with: brew install latexml" >&2
  exit 1
fi
if [ ! -f "$SRC/graypaper.tex" ]; then
  echo "error: no graypaper.tex in SRC_DIR=$SRC" >&2
  exit 1
fi

VER="$(cat "$SRC/VERSION" 2>/dev/null || echo unknown)"
mkdir -p "$OUT"
echo ">> Building Gray Paper v$VER"
echo ">> source: $SRC"
echo ">> output: $OUT"

# 1. LaTeX -> LaTeXML XML.
#    Run from the source dir so \input{text/...} resolves; preload the stub
#    (which no-ops unsupported packages and maps custom symbol glyphs); send
#    the log to OUT so the pinned source worktree stays pristine.
( cd "$SRC" && latexml \
    --preload=gpstub.sty \
    --path="$REPO_DIR" \
    --dest="$OUT/graypaper.xml" \
    --log="$OUT/latexml.log" \
    graypaper.tex )

# 2. LaTeXML XML -> HTML5 with presentation MathML (light, single-column).
#    gp.css is appended after LaTeXML's default stylesheet so it wins.
latexmlpost \
    --format=html5 \
    --css="$REPO_DIR/gp.css" \
    --dest="$OUT/graypaper.html" \
    "$OUT/graypaper.xml"

# 3. Strip the dark theme LaTeXML's xcolor binding baked onto MathML tokens
#    and inline styles (the GP's \pagecolor{verydarkgray}/\color{white}). gp.css
#    also overrides these, but stripping keeps the HTML self-clean and smaller.
LC_ALL=C sed -i '' \
    -e 's/ mathbackground="#262626"//g' \
    -e 's/ mathcolor="#FFFFFF"//g' \
    -e 's/background-color:#262626;\{0,1\}//g' \
    -e 's/color:#FFFFFF;\{0,1\}//g' \
    "$OUT/graypaper.html"

# 4. Inject the fixed sidebar table of contents.
python3 "$REPO_DIR/toc.py" "$OUT/graypaper.html"

echo ">> Done: $OUT/graypaper.html"

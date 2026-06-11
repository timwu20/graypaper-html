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
latexmlpost \
    --format=html5 \
    --dest="$OUT/graypaper.html" \
    "$OUT/graypaper.xml"

echo ">> Done: $OUT/graypaper.html"

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

# Portable in-place sed: BSD/macOS needs an explicit (empty) backup suffix as a
# separate arg; GNU/Linux sed must not get one. Detect by probing --version.
if sed --version >/dev/null 2>&1; then SEDI=(-i); else SEDI=(-i ''); fi

if ! command -v latexml >/dev/null 2>&1; then
  echo "error: latexml not found. Install with: brew install latexml" >&2
  exit 1
fi
if [ ! -f "$SRC/graypaper.tex" ]; then
  echo "error: no graypaper.tex in SRC_DIR=$SRC" >&2
  exit 1
fi

VER="$(cat "$SRC/VERSION" 2>/dev/null || echo unknown)"

# Pin the title date to the version's release (HEAD commit) date instead of the
# build date that \today would produce. gpstub reads GP_DATE at begin-document.
if [ -z "${GP_DATE:-}" ] && git -C "$SRC" rev-parse HEAD >/dev/null 2>&1; then
  GP_DATE="$(git -C "$SRC" log -1 --format=%cd --date=format:'%B %d, %Y' \
             | sed 's/ 0\([0-9]\),/ \1,/')"
fi
export GP_DATE
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

# 2. Bibliography: parse biblio.bib into LaTeXML XML so \cite resolves and a
#    References section is generated (the GP uses biblatex, which LaTeXML lacks).
if [ -f "$SRC/biblio.bib" ]; then
  # Normalize first (synthesize arXiv eprint URLs LaTeXML wouldn't otherwise link).
  python3 "$REPO_DIR/bibnorm.py" "$SRC/biblio.bib" "$OUT/biblio.bib"
  latexml --preload=gpstub.sty --path="$REPO_DIR" \
      --dest="$OUT/biblio.bib.xml" --log="$OUT/biblio.log" \
      "$OUT/biblio.bib"
  BIB_OPT=(--bibliography="$OUT/biblio.bib.xml")
else
  BIB_OPT=()
fi

# 3. LaTeXML XML -> HTML5 with presentation MathML (light, single-column).
#    gp.css is appended after LaTeXML's default stylesheet so it wins.
latexmlpost \
    --format=html5 \
    --css="$REPO_DIR/gp.css" \
    "${BIB_OPT[@]}" \
    --dest="$OUT/graypaper.html" \
    "$OUT/graypaper.xml"

# 4. Strip the dark theme LaTeXML's xcolor binding baked onto MathML tokens
#    and inline styles (the GP's \pagecolor{verydarkgray}/\color{white}). gp.css
#    also overrides these, but stripping keeps the HTML self-clean and smaller.
LC_ALL=C sed "${SEDI[@]}" \
    -e 's/ mathbackground="#262626"//g' \
    -e 's/ mathcolor="#FFFFFF"//g' \
    -e 's/background-color:#262626;\{0,1\}//g' \
    -e 's/color:#FFFFFF;\{0,1\}//g' \
    "$OUT/graypaper.html"

# 5. Inject the fixed sidebar table of contents.
python3 "$REPO_DIR/toc.py" "$OUT/graypaper.html"

# 6. Pin the title date: \today rendered the build date (it expands in the
#    preamble's \title, before any override can catch it), so replace it with the
#    version's release date everywhere it appears.
if [ -n "${GP_DATE:-}" ]; then
  BUILD_DATE="$(date '+%B %e, %Y' | sed 's/  */ /g')"
  LC_ALL=C sed "${SEDI[@]}" "s/$BUILD_DATE/$GP_DATE/g" "$OUT/graypaper.html"
fi

echo ">> Done: $OUT/graypaper.html (dated $GP_DATE)"

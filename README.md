# graypaper-html

A reproducible recipe for building a **light, single-column HTML + MathML** render
of the JAM Gray Paper from its LaTeX source — readable in any browser, with real
rendered math and per-section/equation anchors, on a light background.

This is an alternative to:

- the official **PDF** (dark by design: `\pagecolor{verydarkgray}`), and
- the [Fluffy Labs reader](https://graypaper.fluffylabs.dev/), which displays that
  same PDF (with a client-side light-invert toggle).

It does **not** vendor the Gray Paper source or the generated output — it builds
from a separate source checkout and the output is git-ignored (it's large and
fully reproducible).

## Prerequisites

```sh
brew install latexml
```

A checkout of the Gray Paper LaTeX source (https://github.com/gavofyork/graypaper),
e.g. at `~/dev/graypaper`, checked out to the version tag you want to render.

## Build

Build all versions (into `dist/<version>/`, with a cross-version toggle):

```sh
./build-all.sh          # builds 0.8.0 and 0.7.2, wires up the version selector
./serve.sh              # http://localhost:8722/  (redirects to latest)
```

Or a single version:

```sh
./build.sh [SRC_DIR] [OUT_DIR]   # defaults: ~/dev/graypaper -> ./dist
```

Versions and their source checkouts are configured at the top of
[`build-all.sh`](build-all.sh). Each page has a **version dropdown** (top of the
sidebar) that switches to the same anchor in the other version's build.

## Theme & fonts

The output is a **light, centered single-column** page. Body text uses Computer
Modern (`Latin Modern Roman`/`CMU Serif`) if installed, else **STIX Two Text**;
math uses `Latin Modern Math` else **STIX Two Math** — a PDF-like serif with full
math-glyph coverage. Styling lives in [`gp.css`](gp.css), appended after
LaTeXML's default stylesheet.

The Gray Paper hardcodes a dark theme (`\pagecolor{verydarkgray}` +
`\color{white}`), which LaTeXML's `xcolor` binding bakes onto every MathML token
as `mathcolor="#FFFFFF" mathbackground="#262626"` (rendering as dark boxes on a
light page). `build.sh` strips those attributes after conversion, and `gp.css`
also overrides them — so the math renders dark-on-white.

A fixed **sidebar table of contents** (all sections/subsections, anchor links) is
injected by [`toc.py`](toc.py) as the last build step; it re-runs idempotently.

Preview while iterating on the CSS with [`shot.sh`](shot.sh) (headless Chrome
screenshot): `./shot.sh out.png dist/graypaper.html 1300,2000`.

To view, serve the `dist/` dir (relative CSS/font/image paths need a real origin):

```sh
./serve.sh   # idempotent; serves http://localhost:8722/graypaper.html
```

### Deep links

Stable anchors for citing specific places:

| Target | Anchor | Example |
|---|---|---|
| Section *n* | `#S<n>` | `#S5` (§5 The Header) |
| Subsection *n.m* | `#S<n>.SS<m>` | `#S2.SS1` (§2.1) |
| Equation *(n.m)* | `#S<n>.E<m>` | `#S13.E9` (eq 13.9) |
| Appendix *n* | `#A<n>` | `#A1` |
| References | `#bib` | — |
| A reference | `#bib.bibN` | `#bib.bib4` |

## How it works

LaTeXML converts LaTeX → XML → HTML5 + MathML, and flattens the two-column
`multicols` layout into single-column flow. The Gray Paper's preamble uses
several packages LaTeXML has no bindings for (and which aren't on disk without a
TeX install) plus custom symbol glyphs. [`gpstub.sty.ltxml`](gpstub.sty.ltxml) is
a LaTeXML binding, preloaded before the document, that:

- **no-ops** layout/page machinery irrelevant to HTML
  (`tikz`/`\usetikzlibrary`, `eso-pic`/`\AddToShipoutPicture`, `pagecolor`/
  `\color`, `changepage`, `stackengine`, `\makegpbackground`,
  `biblatex`/`\printbibliography`);
- **stubs** `\makecell`/`\thead` to pass their content through (fixes the PVM
  tables); and
- **maps** ~14 custom math glyphs (`\lsem \rsem \langlebar \ranglebar \nwspoon
  \sespoon \downspoon \lwavy \backsim \blacksquare \lightning \circledcirc
  \circleddash`) to nearest Unicode math characters.

The build runs from `SRC_DIR` so `\input{text/...}` resolves, and writes its log
to `OUT_DIR` so the (pinned) source worktree stays clean.

## Known limitations

- **No bibliography** — `biblatex` is stubbed, so `\autocite`s render thin/empty.
- **Custom glyphs are approximations** — e.g. the "spoon" set-operators map to
  `∖`/`⊓`; semantically close, not pixel-identical to Gav's fonts.
- **PVM tables** render but are visually rougher than the PDF (`makecell`/
  `stackengine` stubbed).
- Single ~4.4MB HTML file; `latexmlpost --split` could split it into per-section
  pages if navigation/load time matters.

These are all in scope to improve by extending the stub or installing a TeX
distribution (so LaTeXML can read the real `.sty` files).

#!/usr/bin/env python3
"""Inject a fixed sidebar table-of-contents into the LaTeXML Gray Paper HTML.

Extracts every section / subsection / subsubsection / appendix heading (by id)
and prepends a <nav id="gp-toc"> with anchor links. Idempotent: a previously
injected nav is removed first, so it is safe to re-run.
"""
import re
import sys

LEVEL = {"section": 1, "appendix": 1, "subsection": 2, "subsubsection": 3}

path = sys.argv[1] if len(sys.argv) > 1 else "dist/graypaper.html"
html = open(path, encoding="utf-8").read()

# Drop any prior injection so re-runs don't stack.
html = re.sub(r'<nav id="gp-toc">.*?</nav>\n?', "", html, flags=re.S)

pat = re.compile(
    r'<section id="([^"]+)" class="ltx_(section|subsection|subsubsection|appendix)">'
    r'\s*<h[2-4][^>]*>(.*?)</h[2-4]>',
    re.S,
)

def text_of(fragment: str) -> str:
    t = re.sub(r"<[^>]+>", "", fragment)        # strip inner tags (tag span, math)
    t = re.sub(r"\s+", " ", t).strip()
    return t

items = []
for m in pat.finditer(html):
    sid, cls, title = m.group(1), m.group(2), m.group(3)
    items.append((sid, LEVEL[cls], text_of(title)))

links = [
    f'<a class="gp-toc-l{lvl}" href="#{sid}">{title}</a>'
    for sid, lvl, title in items
]
nav = (
    '<nav id="gp-toc">'
    '<div class="gp-toc-head">Contents</div>'
    + "".join(links)
    + "</nav>\n"
)

html = html.replace("<body>", "<body>\n" + nav, 1)
open(path, "w", encoding="utf-8").write(html)
print(f"injected {len(items)} TOC links into {path}")

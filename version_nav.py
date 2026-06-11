#!/usr/bin/env python3
"""Inject a version selector into a built Gray Paper page.

Usage: version_nav.py <html> <current_version> <version> [<version> ...]

Adds a <select> at the top of the sidebar that switches to the same anchor in
another version's build (sibling dir ../<version>/graypaper.html#<hash>).
Idempotent: a previously injected selector is removed first.
"""
import re
import sys

path = sys.argv[1]
current = sys.argv[2]
versions = sys.argv[3:]

html = open(path, encoding="utf-8").read()
html = re.sub(r'<div id="gp-version">.*?</div>\s*', "", html, flags=re.S)

opts = "".join(
    f'<option value="{v}"{" selected" if v == current else ""}>v{v}</option>'
    for v in versions
)
# On change: go to the sibling version build, preserving the current #anchor.
onchange = (
    "location.href='../'+this.value+'/graypaper.html'+location.hash"
)
block = (
    '<div id="gp-version"><span class="gp-version-label">Gray Paper</span>'
    f'<select onchange="{onchange}">{opts}</select></div>'
)

# Place it as the first child of the sidebar nav.
html = re.sub(r'(<nav id="gp-toc">)', r"\1" + block, html, count=1)
open(path, "w", encoding="utf-8").write(html)
print(f"version_nav: {current} selector with {versions} -> {path}")

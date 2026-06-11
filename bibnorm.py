#!/usr/bin/env python3
"""Normalize biblio.bib for LaTeXML: synthesize a url for arXiv eprint entries.

biblatex links `eprint={ID}, archivePrefix={arXiv}` to arxiv.org, but LaTeXML's
BibTeX reader doesn't know that convention, so such entries render with no link.
We add `url = {https://arxiv.org/abs/ID}` to any arXiv entry lacking a url/doi.
Reads SRC, writes DST (the pinned source bib is left untouched).
"""
import re
import sys

src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()

# Split into @-entries, keeping the leading material.
parts = re.split(r"(?=@\w+\s*\{)", text)
out = []
added = 0
for p in parts:
    has_link = re.search(r"\b(url|doi)\s*=", p, re.I)
    is_arxiv = re.search(r"archivePrefix\s*=\s*\{?\s*arXiv", p, re.I) or re.search(
        r"eprinttype\s*=\s*\{?\s*arxiv", p, re.I
    )
    m = re.search(r"eprint\s*=\s*\{([^}]+)\}", p, re.I)
    if not has_link and is_arxiv and m:
        eid = m.group(1).strip()
        ins = f"  url = {{https://arxiv.org/abs/{eid}}},\n"
        # insert the url field right after the eprint line
        p = re.sub(r"(eprint\s*=\s*\{[^}]+\}\s*,?\s*\n)", r"\1" + ins, p, count=1)
        added += 1
    out.append(p)

open(dst, "w", encoding="utf-8").write("".join(out))
print(f"bibnorm: added {added} arXiv url(s) -> {dst}")

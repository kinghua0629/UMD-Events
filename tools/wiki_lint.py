#!/usr/bin/env python3
"""Wiki health check: broken [[links]], orphan pages, pages missing from index.md, missing frontmatter.

Usage: python3 tools/wiki_lint.py   (from the repo root; exit code 1 if problems were found)
"""
import pathlib
import re
import sys

WIKI = pathlib.Path(__file__).resolve().parent.parent / "wiki"
LINK = re.compile(r"\[\[([^\]|#]+)(?:[|#][^\]]*)?\]\]")
CODE = re.compile(r"`[^`\n]*`")  # links inside `code` are examples
SPECIAL = {"index", "log"}

pages = {p.stem: p for p in WIKI.rglob("*.md")}
dupes = [p for p in WIKI.rglob("*.md") if pages[p.stem] != p]
problems = [f"duplicate page name: {p.relative_to(WIKI)}" for p in dupes]

inbound = {name: set() for name in pages}
for name, path in pages.items():
    text = CODE.sub("", path.read_text(encoding="utf-8"))
    if name not in SPECIAL and not text.startswith("---\n"):
        problems.append(f"missing frontmatter: {path.relative_to(WIKI)}")
    for target in LINK.findall(text):
        target = target.strip()
        if target not in pages:
            problems.append(f"broken link [[{target}]] in {path.relative_to(WIKI)}")
        elif target != name:
            inbound[target].add(name)

index_links = set(LINK.findall(pages["index"].read_text(encoding="utf-8"))) if "index" in pages else set()
for name in pages:
    if name in SPECIAL:
        continue
    if not inbound[name] - {"index", "log"}:
        problems.append(f"orphan (only linked from index/log): {name}")
    if name not in index_links:
        problems.append(f"not listed in index.md: {name}")

for p in problems:
    print(p)
print(f"{len(pages)} pages, {len(problems)} problem(s)")
sys.exit(1 if problems else 0)

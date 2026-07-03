---
name: code-walkthrough
description: Generate a self-contained HTML walkthrough of a code change for review — data-flow-ordered, collapsible step cards (what · why · diff hunk · how-to-verify), a small flow diagram, and a shared house style. Use when asked to "generate/create a code walkthrough", "walk me through these changes", a "review artifact/page", or to render a diff as a readable HTML page. Not for posting inline PR comments or quick textual explanations.
---

# Code walkthrough (HTML artifact)

Produces one **self-contained** `.html` file that explains a change set so a reviewer can understand it top-to-bottom. Styling is centralized so every walkthrough looks the same and can be tuned in one place.

## The shape — don't reinvent it per run

Order steps by **data flow, not the file tree**. Typical backend→frontend spine:

> schema → models/types → services → API contract → UI → glue (scripts/docs/tests)

For other stacks, adapt the spine: entry point → core logic → edges → tests/docs. One logical step may span several files.

Every step card has the same anatomy:

> **what** (one line) · **why** (the decision) · **hunk(s)** (the real diff) · **verify** (how you'd confirm it)

The page renders this content model:

```
{ title, subtitle, meta{files, churn, date}, chips[], decisions[],
  flow[ nodes ],                       // small diagram, ≤5 boxes, 2 categories
  steps[ { n, title, files[], what, why,
           hunks[ {file, lines[ {kind: add|del|ctx, text} ]} ], verify } ],
  run{ steps[], verifyTable[] } }
```

## Files in this skill

- `assets/walkthrough.css` — **the house style. Single source of truth — tweak here.**
- `assets/template.html` — the skeleton: a `<style>` placeholder plus a worked diagram, TOC, and one step to copy.
- `reference/example.html` — a complete real output (andmeter Phase 0). Match this look and density.

## Procedure

1. **Get the change set.** Default to `git diff` (working tree). Honor a given range / branch / PR / explicit files. Pull the **real** hunks — never paraphrase code.
2. **Decompose into steps** along the data-flow spine. Write a one-line *what*, a *why* (the decision), pick the most telling hunk(s), and a concrete *verify*.
3. **Build from the template.** Copy `assets/template.html`. Replace the `__WALKTHROUGH_CSS__` line inside `<style>` with the **verbatim** contents of `assets/walkthrough.css` — inline it, never `<link>` to it, so the artifact stays portable/offline. Fill header, chips, decisions, diagram, TOC, steps, run.
4. **Render code hunks (the part that bites):**
   - Wrap each hunk's lines in `<div class="cb">` — **never `<pre>`**. Inside `<pre>`, the newline between line `<span>`s renders as a blank line; a `div` lets that whitespace collapse while `white-space:pre` on each `.l` keeps the indentation.
   - One source line per `<span class="l KIND">…</span>`, `KIND ∈ add | del | ctx`. Prefix added lines with `+ `, removed with `- `.
   - **Escape inside code:** `&`→`&amp;`, `<`→`&lt;`, `>`→`&gt;` (so TS generics `<T>`, `&&`, `->`, comparisons all render).
5. **Diagram:** a small inline SVG flow (≤ ~5 boxes), at most **2 categories** (e.g. "new" vs "existing"). Fill shapes with the page CSS vars (`--info-bg`, `--surface2`, `--text`, `--muted`, `--faint`) so it adapts to light/dark. Labels short, sentence case.
6. **Write** to `docs/walkthroughs/<slug>.html` in the repo (create the dir), or a path the user gives.
7. **Validate** before handing off (snippet below): parse for well-formedness; confirm balanced `<details>` and `.cb` blocks and that every `#sN` anchor resolves.
8. Open / preview it, and tell the user the path.

## Validation snippet

```
python3 - <<'PY'
from html.parser import HTMLParser
import sys
src=open(sys.argv[1] if len(sys.argv)>1 else "docs/walkthroughs/out.html").read()
voids={'meta','br','hr','img','input','rect','line','path','text','marker','use','source','col','area'}
st=[];err=[]
class P(HTMLParser):
    def handle_starttag(s,t,a):
        if t not in voids: st.append(t)
    def handle_endtag(s,t):
        if t in voids: return
        if not st or st[-1]!=t: err.append((t, st[-1] if st else None))
        else: st.pop()
P().feed(src)
print("OK" if not err and not st else ("BROKEN", err[:5], "unclosed:", st))
PY
```

## Tweaking the style

Edit `assets/walkthrough.css` once — every future walkthrough inherits it (each inlines the current version at generation time). Existing `.html` files are snapshots; regenerate to restyle. Keep it **dependency-free** — no CDN, no web fonts — so artifacts open anywhere offline. The palette/dark-mode live in the `:root` / `prefers-color-scheme` blocks at the top of the CSS; semantic classes (`.step`, `.cb`, `.l.add/.del/.ctx`, `.verify`, `.toc`, `.diagram`) are below.

## Notes / future

- House conventions: sentence case, two font weights, light/dark via `prefers-color-scheme`, timestamps in JST.
- The same content model can also render Markdown — add a `--format md` template rather than forking the model. HTML is the default.

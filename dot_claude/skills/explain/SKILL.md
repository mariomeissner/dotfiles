---
name: explain
description: Generate a self-contained HTML artifact that explains the background concepts needed to follow the current conversation (or a specific topic, if the user names one as an argument). Manual only — invoke ONLY when the user literally types "/explain"; never trigger this proactively from a description match.
---

# /explain — concept primer artifact

Mid-conversation, the user hits something conceptually loaded and wants to get grounded before
continuing — without derailing the main thread into a wall of inline text. This produces one
self-contained `.html` artifact: a map of the relevant concepts, then a section per concept, built
from what's actually being discussed rather than a generic textbook treatment.

**Works mid-plan-mode.** An explicit `/explain` invocation is exactly what plan mode's read-only
restriction isn't meant to block — the user is asking to get grounded *in order to* plan better.
Produce and publish the artifact as normal; don't treat plan mode as a reason to hold back or ask
first.

**Visual design is not this skill's job.** There's no house CSS here — palette, spacing,
typography, dark mode are the `artifact-design` skill's call, calibrated fresh per topic (a quick
primer usually warrants lightweight treatment; let that skill's own calibration decide, don't
override it). What *is* this skill's job, and isn't covered by artifact-design, is content and
structure: which concepts, in what order, how deep, how much interactivity. That's what the
procedure below actually governs.

## Scope

- **Args given** (`/explain prefix caching`): scope tightly to that topic.
- **No args**: scan the active conversation and pick the 2–5 concepts that are actually load-bearing
  for what's being discussed *right now* — not everything mentioned in passing. If the thread has
  drifted, ground on the current sub-topic, not the whole conversation history.

## Procedure

1. **Identify the concepts and their dependency order.** Which ones are foundational vs. derived, so
   the artifact never forward-references a term it hasn't explained yet. This ordering drives both
   the diagram and the section order.
2. **Decide grounding per concept**, in this priority order: **session context** (a project's
   `CLAUDE.md`, prior tool output, files already read this session) **> model knowledge** (for
   well-established/textbook material — data structures, common protocols, generic CS/infra terms;
   stay fast, don't search reflexively) **> WebSearch** (only when a concept is niche,
   vendor-specific, fast-moving, or you're genuinely unsure your knowledge is current/correct).
   Session context wins even over a confident model prior — it's ground truth for *this*
   codebase/system.
3. **Tie every concept back to the actual conversation.** The example inside each section should
   reference the real thing being discussed (the actual model/system/code at hand), not a generic
   stand-in — that's the difference between a primer and a Wikipedia stub.
4. **Load the `artifact-design` skill** (the Artifact tool requires this before any HTML gets
   written) and follow its calibration normally — there's no house style to protect here anymore, so
   just let it decide the visual investment for this topic.
5. **Calibrate content depth and structure against `reference/example.html`** before writing — it's a
   real worked primer. Match its per-concept density (a paragraph, one example, one forward pointer —
   not more) and section shape. Ignore its specific CSS/classes; that's a visual snapshot from an
   earlier version of this skill, not something to replicate — only the content structure matters.
6. **Build the artifact from `assets/template.html`:**
   - Copy the template as a starting skeleton for structure, then style it per the artifact-design
     guidance from step 4 — the template's markup is unstyled on purpose.
   - Fill the header: title, one-line scope, and a line explicitly stating why this matters to the
     current discussion.
   - Fill the top diagram: inline SVG, ≤ ~6 boxes, dependency graph of the concepts (arrows =
     "requires" / "leads to"). This is the map — a reader should get the shape of it even without
     opening a single section below.
   - One `<details>` per concept, in dependency order, **first one open, rest collapsed** — this is a
     behavioral requirement (skimmable by default), independent of however it ends up styled. Each
     has: plain explanation → concrete example tied to the conversation → one-line forward pointer to
     the next concept or back to the original question.
   - Tag each concept foundational or derived (or drop the distinction if it doesn't apply).
7. **Add interactivity only where it clarifies a concept, never as decoration.** The template has two
   worked patterns to adapt or delete:
   - **Before/after toggle** — for a concept best understood as two states of one diagram (e.g.
     "without prefix caching" vs "with prefix caching").
   - **Step-through** — for a sequential process (a request's path through several hops, a state
     machine). Add prev/next controls and a position counter.
   A plain definition doesn't need interactivity — a `<details>` is enough. Don't force a toggle or
   stepper onto a concept that's just static information.
8. **No external resources.** Inline all CSS/JS, no CDN, no web fonts — the Artifact CSP blocks them.
9. **Sanity-check the render before publishing.** Hand-authored SVG (literal coordinates, fan-out
   arrows) is exactly where visual bugs hide between source and output — a box can clip, an arrow can
   miss its target, dark mode can go unreadable. If a browser tool is available, open the file and
   look; if not, at minimum re-check every SVG element's coordinates against its `viewBox` bounds and
   confirm colors will hold up in dark mode per whatever artifact-design's palette guidance was. Don't
   publish a diagram you haven't verified fits.
10. **Publish via the Artifact tool.** Write the file to the scratchpad dir by default (this is a
    throwaway learning aid, not a deliverable to keep in the repo) unless the user asks to keep it.
    Pick a `favicon` emoji that fits the topic.
11. **Reply in chat with one line** pointing at the artifact — don't re-explain the content in text,
    that duplicates the artifact. Don't auto-resume the original task; wait for the user to come back.

## Files in this skill

- `assets/template.html` — unstyled structural skeleton: header, a worked diagram, one foundational +
  one derived concept section (the derived one demos the toggle pattern), and the step-through
  pattern commented out for reference. No CSS — style it per artifact-design's guidance each run.
- `reference/example.html` — a real worked primer (prefix caching vs. PD disaggregation in the ai&
  stack). Use it to calibrate content depth and section structure (step 5) — **not** its visual
  styling, which predates dropping the fixed house CSS.

## Content guidelines (the part artifact-design doesn't cover)

- Concept count: 2–5 sections, dependency-ordered.
- Diagram: distinguish foundational vs. derived concepts visually somehow, ≤ ~6 boxes, short labels.
- Tone: plain explanation, one concrete example tied to the real conversation, one forward pointer per
  concept — see `reference/example.html` for the target density.
- Timestamps in JST if any appear (footer "Generated" line).

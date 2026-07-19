---
description: Audit chezmoi drift + repo sync state and propose a classified catch-up plan
argument-hint: "[optional: path/glob or area to focus on]"
allowed-tools: Bash(chezmoi status:*), Bash(chezmoi diff:*), Bash(chezmoi managed:*), Bash(chezmoi source-path:*), Bash(chezmoi cat:*), Bash(chezmoi verify:*), Bash(git status:*), Bash(git -C:*), Bash(git fetch:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-list:*), Bash(git stash list:*)
---

You are auditing the state of this machine's **chezmoi** dotfiles and producing a
classified catch-up plan. This repo (`/Users/mario/Projects/personal/dotfiles`) is
itself the chezmoi **source directory**, so "the repo" and "the chezmoi source" are
the same tree.

Optional focus argument: `$ARGUMENTS` — if non-empty, restrict the analysis and the
proposed actions to files/areas matching it. If empty, audit everything.

## Phase 1 — Gather state (read-only, do not mutate anything)

Run these and read the output carefully. Batch the independent ones.

1. `chezmoi source-path` — confirm the source root (should be this repo).
2. `git status --short --branch` — uncommitted changes in the source repo.
3. `git stash list` — any stashed work that could be lost.
4. `git fetch --quiet origin && git rev-list --left-right --count origin/main...HEAD`
   — ahead/behind vs remote. (Left = behind/remote-only, right = ahead/local-only.)
   Per Mario's global rule: never trust stale local refs — always fetch first.
5. `chezmoi status` — drift between live `$HOME` files and the source. This is the core signal.
6. For every entry `chezmoi status` reports (or those matching `$ARGUMENTS`), run
   `chezmoi diff -- <path>` to see the actual content difference. **You must inspect the
   diff content** — the classification in Phase 3 depends on judging what each change *is*,
   not just that it exists.

### Reading `chezmoi status` codes

Two columns `XY` per file. `X` = last-written-state → actual live file. `Y` = actual live
file → target (what the source would produce on `apply`). Codes: ` `=unchanged, `M`=modified,
`A`=added, `D`=deleted, `R`=run (script).

- **` M` (space, M)** — source is *ahead* of the live file; `chezmoi apply` would update `$HOME`.
  The change originated in the repo (e.g. you edited a `dot_*` file or pulled it).
- **`M ` (M, space)** — the **live file drifted** after the last apply; the repo is unaware of it.
  Candidate to either capture (`re-add`) or discard (`apply`).
- **`MM`** — both: the live file drifted **and** it now differs from source. Ambiguous by
  code alone — the diff content decides. Inspect it.
- `A`/`D` — file added or removed on one side; note direction the same way.

## Phase 2 — Judge intent (per changed file)

For each changed file, decide whether the **live-side** change looks **intentional** or
**unintended**, using the diff content and these heuristics:

**Likely UNINTENDED live drift** (noise the repo should not absorb → clean up):
- Machine/tool-managed churn: rotated auth tokens, session IDs, timestamps, cache/version
  stamps, `updated_at`, telemetry, editor/tool state written on exit.
- Content that is per-machine or secret and shouldn't be in git at all (→ flag for
  `.chezmoiignore` or a template/secret mechanism, not a commit).
- A partial/accidental edit, or a revert of something the repo intentionally sets.

**Likely INTENTIONAL local update** (capture into dotfiles → `re-add` + commit):
- A deliberate config change you'd want on every machine: a new alias, a setting toggle,
  a new tool config, an edited keybinding.
- Coherent, human-looking edits that match the file's purpose.

When genuinely unsure, **say so and ask** rather than guessing — do not silently commit or
discard. Remember `.ssh/config`, `hosts.yml`, and anything credential-adjacent are
high-stakes: never propose committing secrets; if a real drift there looks intentional,
recommend a template/ignore approach and ask.

## Phase 3 — Produce the classified plan

Present a concise report (JST timestamps if you show any). Group findings into these buckets,
and for each item give the file, a one-line reason, and the exact command:

1. **🧹 Clean up locally** — unintended live drift to discard by re-applying source:
   `chezmoi apply -- <path>` (this overwrites the live file — note it's destructive to the
   live edit).
2. **📥 Capture into dotfiles** — intentional local updates to pull back into the source:
   `chezmoi re-add -- <path>` (or `chezmoi add` for new files), then a single
   `git add … && git commit` staging them. Author is always Mario's own account; **no AI
   co-author trailer** (per global rules).
3. **🚫 Neither — ignore/secret** — drift that shouldn't be committed *or* blindly overwritten:
   propose a `.chezmoiignore` entry or template/secret handling, and explain.
4. **🔄 Repo sync** — based on Phase 1 step 4:
   - Behind remote → `git pull --rebase origin main` (propose before local commits if it's clean).
   - Ahead / new commits → `git push` after the Phase-3.2 commit lands.
   - Diverged → explain and recommend an order.

End with a short **recommended execution order** (typically: pull → discard noise → capture &
commit intentional drift → push). Then **stop and ask for confirmation** before running
anything mutating. Do **not** run `chezmoi apply`, `re-add`, `add`, `git commit`, `git pull`,
or `git push` until Mario approves the plan — Phase 1 is the only part you run unprompted.

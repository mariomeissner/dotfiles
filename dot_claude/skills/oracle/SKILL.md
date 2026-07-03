---
name: oracle
description: Consult OpenAI Codex (codex CLI) as an independent second-opinion oracle — question-shaped consults about existing code, or an adversarial review of a diff. Use when stuck on a hard bug after 2+ failed hypotheses, when a design decision or subtle conclusion deserves independent review, before merging significant work, or when the user says "ask codex", "ask the oracle", or "get a second opinion".
---

# oracle — second opinion from OpenAI Codex

Run `codex exec` headless against the relevant repo. Codex reads the code itself, so give it
pointers, not pasted dumps. Two recipes, same flags.

## Recipe 1 — question-shaped consult (stuck bug, design review, verify a conclusion)

```bash
codex exec --ephemeral --sandbox read-only --color never \
  -c model_reasoning_effort=high \
  -C <git-repo-root> \
  -o <scratchpad>/oracle-answer.md \
  "$(cat <<'EOF'
<self-contained brief>
EOF
)" </dev/null
```

The brief must be self-contained — Codex shares no conversation state. Include: the goal, the
precise question, relevant `path:line` pointers (let Codex read the files), what has been tried
and ruled out, and any constraints. End with the concrete question.

## Recipe 2 — adversarial diff review (before merging significant work)

Same invocation, with a prompt like:

```
Adversarial code review of <scope — e.g. "the uncommitted working-tree changes (run git status
and git diff yourself)" or "the diff vs origin/main">. Focus on edge cases, security,
performance, and alternative approaches. Question the chosen design, not just the
implementation. Be skeptical.
```

Always state the diff scope explicitly — "recent changes" is ambiguous to a fresh session.
Codex can run the git commands itself in the read-only sandbox.

## Flag rules (all learned the hard way — keep them)

- **Always `--sandbox read-only`.** The oracle advises; you implement. Never grant it writes.
- **`-c model_reasoning_effort=high`** — the user's codex config defaults to *none*, which
  defeats the purpose of an oracle.
- **`</dev/null`** — without a TTY, codex appends stdin to the prompt and can hang waiting
  for EOF.
- **Read the answer from the `-o` file, not stdout** — stdout is the full work transcript
  (banner, every command it ran, token counts); the file is exactly the final message.
- **`-C` must be a git repo root** (e.g. `~/Projects/aiand/uni`, not `~/Projects/aiand` — that
  folder is not a repo). For a non-repo directory add `--skip-git-repo-check`.
- Codex sees the **working tree as-is**, including uncommitted changes.
- **Timeout:** pass `timeout: 600000` to Bash — codex explores for minutes (~5 min typical).
  For open-ended questions, run in the background and continue other work.
- **`--ephemeral`** keeps sessions off disk. If a follow-up exchange seems likely, omit it and
  continue with `codex exec resume --last "<follow-up>"` — but don't loop more than twice;
  refine the brief instead.
- **Model:** omit `-m` to use the configured default. Only override if the user asks.
- **Web search:** add `-c tools.web_search=true` when the question benefits from external
  facts (library versions, upstream bugs, API behavior). It is OpenAI's server-side
  `web_search` tool, so it works fine under the read-only sandbox. Note `exec` rejects the
  `--search` flag — that spelling is interactive-mode only.

## Handling the answer

- Treat it as **advisory, not authoritative**: verify concrete claims (file paths, line
  numbers, API behavior) against the code before acting on them.
- When relaying to the user, attribute it ("codex thinks…") and state whether you agree.
  If you and codex disagree, present both views and your reasoning — disagreement is signal,
  don't silently discard either side.

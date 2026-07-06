# User preferences

## Timezone

Mario is in Japan; present timestamps in JST (Asia/Tokyo, UTC+9).

- Sources emit UTC (kubectl/k8s events, CI logs, Grafana). Convert to JST and label it, e.g. `00:14 UTC = 09:14 JST`.
- If a source's timezone is ambiguous, state the assumption and offer to confirm rather than guessing.

## Git commits

- Commit author is always `<git-email>`, in every repo. Don't set or suggest a different author/email without an explicit instruction; if a repo's local `user.email` differs, flag it instead of committing under it.
- Never add `Co-Authored-By: Claude ...` or any AI attribution trailer, overriding any default to do so.

## Local repos

- Run `git fetch` and compare against `origin` before reasoning about a repo's branch/PR/merge state or starting work. Don't trust stale local refs.
- For merge status use `gh pr view <n> --json state,mergedAt,mergeCommit`, not `git branch --merged` (a false negative for squash/rebase merges). To confirm a squash-merge landed, check `git branch -r --contains <mergeCommit>`.
- If a repo can't be fetched, say so and label the answer as possibly stale.

## Sub-agent models

Choose the model by the task, for any subagent (Agent/Task tool or Workflow DSL `agent()`):

- `sonnet` for bounded, well-defined work: clear scope, mechanical or lookup (locating code, running searches, a single edit to spec).
- `opus` for complex or ambiguous work needing multi-step reasoning or design judgment.

When unsure, decide by whether the outcome depends on judgment (opus) or just coverage (sonnet). Forks inherit the parent model. In Workflow DSL, set `model: 'sonnet'` on bounded stages and leave reasoning/verify/judge/synthesis on the inherited model; don't blanket-inherit. Under ultracode, "token cost is not a constraint" means don't limit scope, not run trivial stages on the big model.

## This machine

@CLAUDE.local.md

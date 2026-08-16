# taste-written-down

> **Agents forget. Files don't.**
> Six copyable artifacts that make an AI agent *more correct* over time — not just faster: eval files, forbidden-string lists, review chains, adversarial fixtures, watch lists, run logs.
> `npx taste init` writes them into your repo in 60 seconds, seeded from your own code.
> Every pattern runs in production in one solo system — with the failures it caught and the ones it hasn't caught yet.
> **Read [LIMITS.md](LIMITS.md) first** if you want to know what doesn't work yet.

---

## Why this exists

Agents got fast. Correctness didn't come along. Every session starts with the same
amnesia, and every "improvement" is judged by vibes — *this output feels better*.

The fix isn't a better prompt. It's **constraint files**: durable artifacts that
encode what "good" means for YOUR project, get loaded automatically, and fire
mechanically when violated. Taste, written down.

"Evals are taste written down" — this repo takes that literally.

## The six artifacts

| Artifact | What it does | Template |
|---|---|---|
| **EVALS.md** | Golden examples + known failures + criteria. The quality bar for a project's fuzzy outputs. | [templates/EVALS.md](templates/EVALS.md) |
| **forbidden-strings.txt** | The failure table made greppable. CI fails on any match. | [templates/forbidden-strings.txt](templates/forbidden-strings.txt) |
| **Review chain** | Multi-round adversarial reviews where each round must state what prior conclusions it invalidates. | [templates/REVIEW-CHAIN.md](templates/REVIEW-CHAIN.md) |
| **Adversarial fixture** | A deliberately hostile test subject that breaks when your abstraction leaks. | [templates/tracer-fixture.md](templates/tracer-fixture.md) |
| **Watch list** | Deferred adoptions with explicit revisit triggers. Future-proof = adoptable late, not early. | [templates/watch-list.md](templates/watch-list.md) |
| **Run log** | One dated line per significant outcome, appended to the skill/tool's own file. | [templates/run-log.md](templates/run-log.md) |

## Quick start

```bash
npx taste init          # in any repo — proposes domain-specific forbidden strings,
                        # writes evals/EVALS.md, evals/forbidden-strings.txt,
                        # ci/check-constraints.sh, pre-commit hook,
                        # and appends @-imports to CLAUDE.md/AGENTS.md

taste review <file>     # 3-round adversarial review with invalidation ledger
```

No API key needed. `taste init` reads your repo and proposes constraints; you accept or edit. The grep runs locally.

## The patterns

1. [Evals as constraint files](patterns/01-evals-as-constraint-files.md) — the lead pattern
2. [Review chains](patterns/02-review-chains.md) — disagreement as fuel, invalidation as rule
3. [Adversarial fixtures](patterns/03-adversarial-fixtures.md) — break your own abstractions on purpose
4. [Constraint loading](patterns/04-constraint-loading.md) — pointers don't load; @-imports do
5. [Watch lists](patterns/05-watch-lists.md) — deferring adoption, with triggers

## The case study

[3,158 lines of game vision → 18 locked architecture decisions in 2 days](case-study/README.md) —
with real review transcripts and the before/after diffs (including the moment
a German grammar error in the flagship example got caught and fixed).

## Limits (read this)

This system is **n=1, solo, built in one week**. The forbidden-strings file has **never
fired in production** — its 20 patterns were mined from a review transcript, not CI
failures. The read-at-start loop is only half closed (Claude Code auto-loads via
@-imports; other agents get pointers). The write side — updating evals after each run —
is entirely manual. Full honesty in [LIMITS.md](LIMITS.md).

## License

MIT

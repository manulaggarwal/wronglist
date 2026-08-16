# wronglist

> **Agents forget. Files don't.**
> Six copyable artifacts that make an AI agent *more correct* over time — not just faster: eval files, wronglists, review chains, adversarial fixtures, watch lists, run logs.
> `wronglist init` writes them into your repo in 60 seconds, seeded from your own code.
> Every pattern runs in production in one solo system — with the failures it caught and the ones it hasn't caught yet.
> **Read [LIMITS.md](LIMITS.md) first** if you want to know what doesn't work yet.

---

## Why "wronglist"?

Every project accumulates a private list of mistakes that must never happen
again. Most teams keep it in someone's head. Agents don't have that head.
The wronglist is that list, written down where every agent, every review,
and every CI run can be held to it.

`npx wronglist init` → `evals/wronglist.txt` → CI fails when a known-wrong
pattern reappears. That's the whole idea.

## The six artifacts

| Artifact | What it does | Template |
|---|---|---|
| **EVALS.md** | Golden examples + known failures + criteria. The quality bar for a project's fuzzy outputs. | [templates/EVALS.md](templates/EVALS.md) |
| **wronglist.txt** | The failure table made greppable. CI fails on any match. | [templates/forbidden-strings.txt](templates/forbidden-strings.txt) |
| **Review chain** | Multi-round adversarial reviews where each round must state what prior conclusions it invalidates. | [templates/REVIEW-CHAIN.md](templates/REVIEW-CHAIN.md) |
| **Adversarial fixture** | A deliberately hostile test subject that breaks when your abstraction leaks. | [templates/tracer-fixture.md](templates/tracer-fixture.md) |
| **Watch list** | Deferred adoptions with explicit revisit triggers. Future-proof = adoptable late, not early. | [templates/watch-list.md](templates/watch-list.md) |
| **Run log** | One dated line per significant outcome, appended to the skill/tool's own file. | [templates/run-log.md](templates/run-log.md) |

## Quick start

```bash
git clone https://github.com/manulaggarwal/wronglist && export PATH="$PWD/wronglist/bin:$PATH"
# (npm publish pending — the CLI is dependency-free Node, clone-and-run works today)

wronglist init          # scan repo → propose wronglist entries → write evals/ + CI
                        # + @-imports into CLAUDE.md/AGENTS.md (no API key, local only)

wronglist check         # grep the wronglist — exit 1 on match, 0 clean, 2 config
wronglist review FILE   # print the 3-round review-chain prompt for FILE
```

Example — init in a repo with real issues:

```
$ wronglist init
  + evals/wronglist.txt (2 proposals — EDIT ME)
    TODO          # found in README
    Lorem ipsum   # placeholder in src/app.js
  + evals/EVALS.md (skeleton — fill §1 with 3 golden examples)
  + ci/check-constraints.sh (exit 1 on any match)

$ wronglist check src
  src/app.js:1:console.log("TODO implement");
  ✗ WRONGLIST MATCHES FOUND — fix, or record in EVALS.md §2 if it's a known failure.
```

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

This system is **n=1, solo, built in one week**. The wronglist has **never
fired in production** — its 20 patterns were mined from a review transcript,
not CI failures. The read-at-start loop is only half closed (Claude Code
auto-loads via @-imports; other agents get pointers). The write side —
updating evals after each run — is entirely manual. Full honesty in
[LIMITS.md](LIMITS.md).

## License

MIT

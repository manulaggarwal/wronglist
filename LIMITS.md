# LIMITS.md — what doesn't work yet

Read this before adopting anything here. Every pattern in this repo is real and
in production, and every one of them has a hole. Most repos hide these; ours is
the differentiation.

## 1. The forbidden-strings file has never fired

`evals/wronglist.txt` in the case-study project holds 20 patterns
(invented words, wrong articles, dangerous content). **Zero have ever been caught
by CI** — because no content exists yet to check. The patterns were mined from
an adversarial review transcript, not from production failures. The mechanism ships green on
its own test suite (dirty repo → exit 1, clean → exit 0 — verified after the
first published version shipped with inverted exit logic, caught by review);
the *catch rate* on real content is unproven. We'll update this file the
day it fires for real.

## 2. The read-at-start loop is half closed

- **Claude Code:** `@imports` in CLAUDE.md genuinely inline the constraint files at
  session start. Verified: an auditor found the forbidden strings in its context
  unprompted.
- **Other agents:** they get *pointers* ("see evals/wronglist.txt").
  A pointer is not a load. Whether any given agent opens the file is an election,
  and elections are exactly what the mechanism exists to remove.
- **The write side is manual.** Nothing automatically appends outcomes to EVALS.md
  or run logs after a session. The loop is: automatic read, human write.

## 3. n=1, solo, one week old

Every pattern here was built and used by one person on one system (a solo
developer with 16 agent profiles and a game project). No team has adopted this.
No pattern has survived contact with a second user. Treat everything as
"proposed protocol with one worked example," not battle-tested practice.

## 4. The review chain has n=1 too

The "each round must state what it invalidates" rule was adopted *after* a single
instance where it demonstrably worked (Review 3 reconciling against Reviews 1-2).
It is the right rule; it has run exactly once. The case study says so.

## 5. Constraint files can go stale

An EVALS.md nobody updates is worse than none — it grants unearned confidence.
The known-failure table only grows when someone remembers to grow it. We have
no mechanism (yet) for detecting staleness, only a convention ("when a
verification gate catches a flaw, write it in same-day"). Conventions are made
of the same stuff as the failures they prevent.

## 6. The CLI is new code by one author

`wronglist init` reads your repo and proposes constraints. It will propose bad ones
sometimes. Review what it writes before you commit it, same as any tool.
(v0.1 shipped with inverted check-exit logic and an over-quoted CI default —
both caught by an external review round, both fixed. That's this repo's own
pattern working on itself.)

---

These limits are the roadmap. Watch-list triggers for revisiting each one live in
the source system's vault; when they fire, this file changes.

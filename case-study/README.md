# Case study: 3,158 lines of game vision → 18 locked decisions in 2 days

**The project:** Deutschland Journey — a 2D exploration RPG set in Germany
(LÖVE2D), where the player absorbs German by living in it. This case study
covers 2026-08-12 → 2026-08-14: vision → adversarial review → creative review →
reframe → architecture synthesis → system audit.

## The chain

| Round | Framing | What it produced |
|---|---|---|
| 1 — whole-concept adversarial | "find everything wrong" | 22 content failures (incl. 2 unsafe-to-ship), wrong B2 premise, editor requirement |
| 2 — creative design | "what's good, what's missing" | 10 named mechanics, the progression fantasy, verb-document mandate |
| 3 — reframe | "the premise was wrong: exploration game, not language product" | invalidated ~half of Round 1 (see ledger), stratification-not-gating, world-first prototype order |
| 4 — architecture | adversarial + constructive on engine/art design | 18 locked decisions; disagreed with the human's own proposal in 6 places |
| 5 — system audit | verify-the-verification | caught: golden examples containing an invented word, a recorded-but-never-fixed failure, an orphaned eval file, desynced decision lists |

Round 5 is the money shot: **the eval file itself taught an error it existed
to prevent** ("Radlane" — an invented word — inside the German golden
examples), and a grammar example still contained `der Brezel` / `die Croissant`
*after* being logged as a known failure. Recording a failure is not fixing it.

## The invalidation ledger (Round 3 excerpt)

> Review 1's core recommendation — the scenario-rehearsal vignette product —
> was **wrong**. It optimized for measurable learning outcomes in a product
> that has none as a goal. Review 1 treated the B2 endgame as content to
> delete. The right move is to delete the *gate*, not the content.

## The receipts

- `reviews/` — the actual review transcripts (rounds 1-4) and the audit summary
- `before-after/der-brezel.md` — the flagship grammar error: flagged, logged,
  still live, then caught again and fixed. The diff that explains the whole method.
- `before-after/evals-radlane.md` — the eval file's own error, found by audit

## What shipped

- `docs/ARCHITECTURE-FINAL.md` — 18 locked decisions, each traceable to a section
- `docs/EVALS.md` + `evals/wronglist.txt` — the quality bars (this repo's lead pattern, in production)
- A git repo, a CLAUDE.md with @-imports, and a daily-log discipline

## Timeline (honest)

Vision existed before 08-12. Everything else: **2 days, ~5 agent-hours of
review compute, one human deciding.**

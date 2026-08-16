# Review chain — adversarial rounds with an invalidation ledger

*One review is an opinion. A chain is a protocol. The ledger is what stops
later rounds from silently inheriting earlier mistakes.*

## The rules

1. **N rounds, different framings.** Round 1 adversarial (find what's wrong),
   later rounds creative/constructive (find what's right and missing).
   Feed each round the prior rounds' outputs.
2. **The invalidation rule:** EVERY round must end with a section stating
   what prior conclusions it invalidates. "Where I was wrong" is required,
   not optional. If a round invalidates nothing, say so explicitly.
3. **Mine disagreements.** When rounds disagree, the resolution gets written
   down as a criterion (→ EVALS.md §3). The argument dies; the principle stays.
4. **Verify claims against reality.** The reviewer must read actual files,
   not trust the brief. Every claim: check the disk.
5. **Human closes the loop.** The chain proposes; the owner disposes. Locked
   decisions get recorded once, in one canonical place.

## Round prompt skeleton

You are reviewing <artifact>. Read the actual files at <paths>.
Prior rounds: <attached>. Be adversarial/constructive per round N.
End with: (a) verdict per area, (b) what's RIGHT, (c) what needs fixing,
(d) **WHAT PRIOR CONCLUSIONS THIS ROUND INVALIDATES**, (e) top 3 fixes ranked.

## Ledger format (keep in the project)

| Round | Invalidated | Reason |
|---|---|---|
| 3 | R1's "cut the X system" | Reframed premise: X is the product, not a feature |

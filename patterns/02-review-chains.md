# Pattern 2: Review chains with an invalidation ledger

*One review is an opinion. A chain is a protocol.*

## The mechanism

Run N review rounds over the same artifact with different framings:

- Round 1: **adversarial** — find what's wrong, missing, oversold
- Round 2: **constructive** — what should this become?
- Round 3: **synthesis** — decide, lock, extract criteria

Two rules make it a protocol instead of three chats:

1. **The invalidation rule.** Every round must end with "what prior
   conclusions this round invalidates." Required, even if the answer is
   "none." This stops later rounds from silently inheriting earlier
   mistakes — the review-chain version of blast radius: an error in round 1
   poisons every round that consumes it uncritically.
2. **Verify against disk.** The reviewer reads the real files. Briefs are
   claims; the disk is truth. (Our audits routinely catch brief-vs-disk
   drift: wrong counts, files claimed missing that exist, decisions claimed
   locked that aren't.)

Then mine the disagreements: each resolved dispute becomes a one-line
criterion in EVALS §3. That's the compounding asset.

## Status: protocol, n=1

Honest basis: the invalidation rule ran once, visibly, when a reframe round
invalidated ~half of round 1's conclusions ("cut this system" → "the system
IS the product"). It worked. It has not run a second time. Use it, report
back.

## Template

`templates/REVIEW-CHAIN.md` — round prompts + the ledger table format.
The CLI prints the 3-round prompt: `wronglist review <file>`.

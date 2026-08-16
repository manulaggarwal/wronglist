# The der Brezel receipt

**The failure:** the project's flagship grammar-teaching example — the worked
demo of how the game teaches German noun gender — contained `der Brezel` and
`die Croissant`. Both wrong. The example exists to teach articles.

**Round 1 flagged it.** The adversarial review listed both errors with correct
versions.

**The failure table recorded it.** When EVALS.md was created days later, both
went into §2 "Known failures (must not recur)."

**...and the file was never fixed.** Round 5 (system audit), reading actual
files instead of trusting the docs, found both errors still live in
`docs/grammar-teaching-example.md` — in the repo AND the mirrored vault.

## The fix (2026-08-14)

```diff
- Items on counter with faint labels: der Brezel, das Brot, der Kuchen
+ Items on counter with faint labels: die Brezel, das Brot, der Kuchen

- die Croissant ████░░░░░░░  30% (just learned)
+ das Croissant ████░░░░░░░  30% (just learned)
```

## The lesson (now a rule in templates/EVALS.md)

> Recording a failure is not fixing it.

A known-failures table creates the *feeling* of resolution. Fix the source,
then record it — the audit round's exact words: *"a wrong article in the
scaffold of a document about articles is the finding itself."*

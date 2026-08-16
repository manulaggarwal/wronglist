# EVALS.md — quality bars for this repo

*Evals are taste written down. Judge fuzzy outputs against this file.*

## §1 Golden examples (known-good)

### Clean check output
`status: verified-by-CI 2026-08-16 · context: CLI UX · situation: no matches found`

```
✓ clean — no wronglist matches in: lib
```

**Why it's good:** one line, says what was checked and where, exit 0. No noise.

### Violation output
`status: verified-by-CI 2026-08-16 · context: CLI UX · situation: matches found`

```
src/app.js:1:console.log("TODO implement");

✗ WRONGLIST MATCHES FOUND — fix, or record in EVALS.md §2 if it's a known failure.
```

**Why it's good:** shows the match, tells you the two legal responses (fix it, or
acknowledge it as known), exits 1. The error message teaches the workflow.

## §2 Known failures (must not recur)

| ❌ Pattern | Why | Correct version |
|---|---|---|
| `execSync(...)` success read as violation | grep exits 0 on MATCH — inverted try/catch logic shipped in v0.1 | matches → exit 1; no matches (grep exit 1) → clean. Tested both paths. |
| `SCOPE=("\${@:-...}")` | quoting collapses defaults into one literal string; CI silently green | `if [ $# -gt 0 ]; then SCOPE=("$@"); else SCOPE=(defaults); fi` |
| Pattern file keeps trailing whitespace | `"TODO  "` never matches `"TODO"` | strip `[[:space:]]*$` in both Node and sed paths |
| `docs` in default scope | contradicts pattern 01 — fires on the very docs that record failures | defaults: `src lib app content packs out dist` |

Rule: a caught flaw lands here SAME DAY. Recording ≠ fixing — fix the source too.

## §3 Criteria (from disagreements)

| Criterion | Origin | Statement |
|---|---|---|
| Test both verdict paths | v0.1 inverted-exit bug | A check command is two behaviors; a test that only runs the happy path tests nothing |
| Dogfood before publish | v0.1 shipped broken | The repo's tool must run on the repo before the README claims it works |
| Honesty is the moat | review round vs. competitor repos | LIMITS-first beats feature-first for a trust product |

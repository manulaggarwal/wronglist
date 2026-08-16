# EVALS.md — <project name>

*Evals are taste written down. This file is the quality bar for this project's
fuzzy outputs — the things tests can't check. Everything the agent produces that
matters gets judged against this file. When something fails, it lands here.*

## §1 Golden examples (known-good)

3-5 reference outputs with WHY they're good. Mark status honestly.

### <Example 1 name>
`status: unverified | verified-by <who> on <date>`
`context: region/scope · register/tone · situation`

<the example itself>

**Why it's good:** <one or two lines — the part an agent pattern-matches>

## §2 Known failures (must not recur)

| ❌ Failed pattern | Why it failed | Correct version |
|---|---|---|
| <literal string or pattern> | <one line> | <the fix> |

Rule: when any review, test, or user catches a real flaw → same-day row here.
Recording a failure is not fixing it — fix the source, then record it.

## §3 Criteria (discovered through disagreement)

| Criterion | Origin | Statement |
|---|---|---|
| <name> | <which review/debate> | <one-line principle> |

Add a row every time a disagreement gets resolved — the extracted principle
outlives the argument.

## Usage

- Generating → match §1's register; check §2 before shipping
- Reviewing → grep §2's literal patterns; anything matching FAILS
- New disagreement → extract the criterion into §3

# Run log convention

*One dated line per significant outcome, appended to the tool/skill's own file.
Successes AND failures. Ten seconds per event; six months later you have
outcome data the description field can never give you.*

## Format (append inside the tool's file)

## Run Log

- YYYY-MM-DD: <tool/skill> → <what it did> → <outcome + one lesson>

## Rules

- Log the FAILURE case even when it stings — that's the data you'll want.
- One line. If it needs three, write it in EVALS.md instead.
- Honest beats flattering: "caught a bug mine missed" is the best entry you'll write.
- Reviews/audits count as runs. So do days nothing broke.

## Example (real entries)

- 2026-08-14: system audit via claude -p — caught EVALS German errors + 41 dupe
  files mine missed. Always give reviewers file paths + permission to verify.
- 2026-08-13: web_extract on direct URLs beats the API for single posts —
  zero credits, richer payload. Now the default.

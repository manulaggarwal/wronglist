# Pattern 1: Evals as constraint files

*The lead pattern. If you adopt one thing, adopt this.*

## The problem

Agents produce fuzzy outputs — prose, translations, UI copy, dialogue, docs,
designs. Tests can't check these. So they get judged by vibes: *this feels
better.* Vibes don't survive two people, or two weeks, or an agent update.
And every improvement loop ("change prompt → look → feels better?") can't
distinguish progress from a lucky run.

## The mechanism

A file, per project, with three sections:

1. **Golden examples** — 3-5 known-good outputs, each annotated with *why
   it's good* (the annotation is what an agent pattern-matches). Honest
   provenance: `status: unverified` until a human signs off.
2. **Known failures** — every caught mistake as a row: pattern / why it
   failed / the correct version. Same-day rule: a flaw lands here the day
   it's caught. Recording a failure is not fixing it — fix the source, then
   record it.
3. **Criteria** — principles extracted from resolved disagreements. The
   argument dies; the principle stays.

Then make it bite: literal failure patterns go into a greppable
`wronglist.txt`; CI fails on match (see template). Point the grep at
generated content, never at the historical docs you mined failures from.

## Why it works

- **Faster ≠ more correct.** Skills make agents faster; constraint files are
  what move the correctness axis.
- **The set compounds.** Every useful failure becomes a permanent example.
  Models change; your definition of good keeps improving.
- **It's judgment, externalized.** The senior-person "I know it when I see
  it" becomes reusable by every agent, every session.

## Gotchas

- An EVALS.md nobody updates is worse than none — unearned confidence.
- Golden examples produced by the same model class they police are
  hypotheses, not bars. Mark them unverified. (Ours shipped with an invented
  word — caught by a review round, see the case study.)
- Grep only checks literals. Conceptual failures ("insurance taught wrong")
  need the human checklist.

## Worked example

See `case-study/` — 22 failure rows, 10 criteria, four annotated golden
examples, and the diff of the moment an audit caught the flagship example
teaching an error.

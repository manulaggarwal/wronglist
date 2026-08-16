# Pattern 4: Constraint loading — pointers don't load

*A constraint file that agents must remember to open is a suggestion.
Make loading automatic or accept it will be skipped.*

## The mechanism

Most "agent memory" setups reference their constraint files — a table row in
CLAUDE.md, a mention in a handbook. Reference ≠ load. The agent that doesn't
open the file never sees the constraints, and the failure mode isn't
defiance, it's ignorance.

The fix that works today (Claude Code): **@-imports**.

```markdown
## Always-Loaded Constraints

@evals/forbidden-strings.txt
@evals/EVALS.md
```

The `@path` syntax inlines the file's contents into context at session
start. Verified in our audit: a reviewer found the forbidden strings in its
context unprompted — the election step is gone.

## What this pattern is NOT yet

- **Portable:** @-imports are a Claude Code feature. Other agents get the
  pointer fallback (documented, but an election).
- **Closed-loop:** the read side is automatic; the write side (updating
  evals, run logs after outcomes) is human. Automatic read + manual write.

Keep imported files SHORT — they cost context every session. Import the
constraint list; link the essays.

## The three-decision test

Before making anything resident in a system prompt, ask:
1. Does it need to auto-trigger, or just be available?
2. Cheapest tier that works: referenced → saved → auto-loaded?
3. What's the token cost, and who reports it?

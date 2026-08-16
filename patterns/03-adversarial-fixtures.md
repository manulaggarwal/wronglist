# Pattern 3: Adversarial fixtures

*Break your own abstraction on purpose, in CI, before your users do.*

## The mechanism

Wherever you have an abstraction boundary — engine/content, core/plugin,
library/application — construct the WORST legal input:

- different cardinality than you assume (2 options where code expects 3)
- optional fields missing that code secretly requires
- character sets/encodings you never tested
- empty content paths

Run it in CI. Crashes, misbehavior, silent defaults = your boundary leaks.
Then add a static check for the leak class itself.

## The original: the tracer pack

From a game engine built around country data packs (Germany first, more
later), `packs/xx/` is a deliberately hostile fake country:

```lua
genders = 2          -- not 3: does the engine hardcode der/die/das?
register = nil       -- no formal/informal split: does NPC code require it?
script = "un-latin"  -- multibyte: does string.sub survive?
-- zero NPCs, zero shops, no audio: does boot survive empty content?
```

Plus the static check that catches the leak class outright:

```bash
! grep -rIn -P '[äöüßÄÖÜ]|"(Guten|Brot|München)' engine/
# German must never appear in the engine layer. If it does, someone
# hardcoded the domain into the abstraction.
```

If `xx` breaks, you hardcoded your first country. The fixture has no
opinions about your domain — it only knows where assumptions hide.

## Generalizing

- Plugin system → fixture plugin using every optional-hook-as-absent
- i18n layer → fixture locale with different plural rules and no strings
- API client → fixture server returning valid-but-weird payloads
- Agent skills → fixture consumer with a different OS and no network

# Adversarial fixture — break your own abstraction on purpose

*A deliberately hostile test subject that fails loudly when your abstraction
leaks domain assumptions. Originally `packs/xx/` in a game engine: a fake
country pack with 2 genders instead of 3, no formal-informal register,
non-Latin glyphs, zero content — run in CI to catch hardcoded assumptions
about the real country.*

## The pattern

1. Identify your abstraction boundary (engine/content, core/plugin, lib/app).
2. Construct the WORST legal input: valid per the interface, hostile per the
   assumptions you didn't write down.
   - Different cardinality than you assume (2 options, not 3)
   - Missing optional fields you secretly require
   - Character sets / encodings you never tested
   - Empty content paths
3. Run it in CI. If it crashes, misbehaves, or silently defaults: your
   boundary leaks. Fix the engine, not the fixture.
4. Add a static check for the leak class: e.g. grep for domain-specific
   literals in the generic layer — `[äöüß]` in `engine/` = fail.

## Example (from the case study)

packs/xx/country.lua:
  genders = 2            -- not 3. Does the engine hardcode "der/die/das"?
  register = nil         -- no formal/informal split. Does NPC code require it?
  script = "un-latin"    -- does string handling survive multibyte?

CI: ! grep -rIn -P '[äöüßÄÖÜ]' engine/   # German must never leak into engine/

I read all nine documents on disk — `VISION.md`, `GAMEPLAY-LAYERS.md` (112 layers), `ARCHITECTURE-HERMES.md`, `ARCHITECTURE-FINAL.md`, and the three prior reviews. The repo currently has **zero Lua**, which means every recommendation below is still free to act on. Note that `docs/reviews/claude-architecture-review-2026-08-12.md` — the review `ARCHITECTURE-FINAL.md` cites as one of its two sources — is 0 bytes. The synthesis survived; the source didn't. This is that review, redone independently.

---

# Deutschland Journey — Architecture & Art Direction Review

## 0. The read before the recommendations

Both decisions, as posed, are hedges.

"Maximum modularity so France can drop in" is a hedge against **being trapped by four years of code**. "Two visual options, retro and modern" is a hedge against **not being able to pull off modern**. Neither hedge buys what it's meant to buy. Maximum modularity traps you in a *different* corner — one where every bug is an indirection and every content edit needs a schema migration. Two art pipelines double the surface of the thing you're already least sure you can do.

The correct response to both is the same: **engineer for reversibility, not for generality.** Reversibility is cheap and specific — IDs instead of paths, data instead of code, versioned saves, validated content, tests that run without LÖVE, one art pipeline with a branch in the renderer. Generality is expensive and speculative.

And there is a scope fact that reframes Decision 1 entirely, which neither Hermes nor `ARCHITECTURE-FINAL.md` addresses:

> **You are not building four countries. You are building 112 gameplay layers.**
>
> France is speculative and four years out. Layer #37 (Flohmärkte) is certain and next month. The axis you will actually add along, hundreds of times, is *gameplay layer* — and the architecture in `ARCHITECTURE-FINAL.md` optimizes for the axis you'll cross maybe twice.

Get layer modularity right and country modularity falls out of it for free. Get country modularity right and layer modularity does not.

---

# PART 1 — MODULAR ARCHITECTURE

## 1.0 Verdict

**Three layers (Engine / Game / Pack) is correct.** Build the pack loader on day one. No ECS, no plugin system, no DI, no grammar engine.

**But add a fourth structural unit that neither analysis has: the gameplay layer module**, and make *that* the primary extension point. And make five specific corrections to `ARCHITECTURE-FINAL.md`, listed in §1.14.

---

## 1.1 The extension axis is layers, not countries

112 documented layers. `GAMEPLAY-LAYERS.md` already contains three hand-drawn "Layer Connection Map" sections — the founder has independently discovered that the interesting structure is the *graph between layers*, not the tree above them.

At even 200 lines and 400 lines of content each, 112 layers is ~22k lines of code and ~45k lines of data. If each layer costs a week because it touches the economy, the notebook, the calendar, the NPC scheduler, and the save format, the project dies of integration, not of scope. If each layer costs a day because it declares what it needs and subscribes to what it cares about, the project is achievable.

So: **every gameplay layer is a module with a fixed, boring shape.**

```lua
-- game/layers/pfand.lua
return {
  id       = "pfand",
  requires = { "econ", "inventory", "notebook" },   -- game-layer services, asserted at load

  -- content this layer expects from the active pack; absent = layer silently disabled
  pack_path = "layers/pfand.lua",
  schema = {
    machines   = { type="list", of="machine_ref" },  -- validated by tools/validate.lua
    deposit    = { type="map", of="number" },
    receipt_ui = { type="string" },
  },

  listens = {                                        -- declared, not registered ad hoc
    ["item.acquired"]   = function(ctx, e) ... end,
    ["place.entered"]   = function(ctx, e) ... end,
  },
  emits = { "pfand.returned", "money.gained" },      -- declared for the graph + dev validation

  verbs = { { id="collect_bottle", ... } },
  init  = function(ctx, content) ... end,
  update = nil,                                       -- most layers need no per-frame update
}
```

Four things fall out of this, all of them load-bearing:

1. **A pack without `layers/pfand.lua` gets no Pfand.** France has no Pfand system, no Stempelheft, no Schrebergarten, no Karneval. That's not a special case you handle — it's the absence of a file. Country modularity is a *free consequence* of layer modularity.
2. **`emits`/`listens` are declared**, so `tools/graph.lua` generates the Layer Connection Map that `GAMEPLAY-LAYERS.md` currently draws by hand. The doc becomes build output. In dev builds, emitting an undeclared event or listening for an event nothing emits is an error — which kills the single most common event-bus bug (a typo'd name silently doing nothing) before it costs you a day.
3. **You can bisect the game.** `layers = {"pfand", "stempel"}` in a dev config boots a two-layer build in a second. With 112 layers you will need this constantly.
4. **It gives you a template**, and templates are how a solo developer sustains 112 of anything.

The rule that makes this work: **layers never call each other.** They call *services* (`econ`, `notebook`, `clock`, `world`) and they emit events. A layer that imports another layer is a merge of two layers.

---

## 1.2 Three layers, and what actually goes where

`ARCHITECTURE-FINAL.md` A3 is right, and the test it doesn't state is this one:

> **Engine:** would a platformer set in Ohio use this unchanged?
> **Game:** would *Voyage en France* use this unchanged?
> **Pack:** does changing this change no code?

| | Contains | Does **not** contain |
|---|---|---|
| `engine/` | canvas stack, integer-scale presenter, SpriteBatch layer renderer, atlas/Quad, palette + LUT + light passes, immediate-mode UI primitives, input, save I/O + versioning, coroutine scheduler, event bus, audio bus, positional audio, text layout **engine** (boxes, wrapping, measurement), pure-Lua fs shim | anything named in German; anything that knows what a "word" is |
| `game/` | lexicon store + acquisition state machine, veil styling, notebook (SEEN/OWN, `Das Unverstandene`), transactions, NPC schedules, place open/closed, calendar, stamps, `Der Wörtliche Geist`, layer registry, **segmenters and morphology analyzers**, service clients | German lemmas; Munich; DIN fonts |
| `packs/de/` | lexicon, authored lines, screens, people, schedules, culture data, per-layer content, art, LUTs, fonts, audio, German UI strings | code that isn't declarative data |

The one boundary people get wrong: **`engine/` owns text *layout*; `game/` owns text *meaning*.** Measuring a glyph run and producing boxes is engine work. Deciding a box is `unknown` and therefore 35% alpha is game work. Deciding that `Handschuh` splits into `Hand` + `Schuh` is pack data.

---

## 1.3 The pack loader — build it, and here is the exact LÖVE mechanic

Hermes says "don't build it yet." That is wrong for one reason, and it is a LÖVE-specific reason:

**The moment you write `require("packs.de.world.muenchen.marienplatz")`, Germany is in the module dependency graph.** That is not a string you grep and swap — it is structure, spread over hundreds of files, and it is the single genuinely brutal retrofit in this project. The loader is ~80 lines and it eliminates the whole category.

But build it correctly, which means **pack Lua is loaded as data, not `require`d as modules**:

```lua
-- game/pack.lua
local P = { id = nil, root = "pack/" }   -- everything resolves through this prefix

-- packs ship as a folder in source, or a .love/.zip mounted from the save dir
function P.mount(id)
  local zip = ("packs/%s.love"):format(id)
  if love.filesystem.getInfo(zip) then
    assert(love.filesystem.mount(zip, "pack"), "mount failed: "..zip)
  else
    P.root = ("packs/%s/"):format(id)     -- dev: read straight from source
  end
  P.id = id
  P.manifest = P.chunk("pack.lua")
end

-- pack Lua is DATA: sandboxed env, no upvalues into the engine, no package.loaded pollution
local SAFE = { math=math, string=string, table=table, ipairs=ipairs, pairs=pairs, tonumber=tonumber }
function P.chunk(rel)
  local path = P.root .. rel
  local fn, err = love.filesystem.load(path)
  if not fn then error(("pack %s: %s -> %s"):format(P.id, path, err), 0) end
  setfenv(fn, setmetatable({}, {__index = SAFE}))   -- LuaJIT is 5.1; setfenv exists
  return fn()
end

function P.image(rel) return love.graphics.newImage(P.root .. rel) end
function P.exists(rel) return love.filesystem.getInfo(P.root .. rel) ~= nil end
```

Why `love.filesystem.load` + `setfenv` rather than `require`:

- **Hot reload is free.** No `package.loaded` entry to invalidate, no stale upvalues. Re-call `P.chunk` and you have new data. Over four years this is worth more than everything else in this section.
- **Packs can't reach into the engine**, which matters the day a pack is downloadable or someone else authors one.
- **Pack data stays serializable and inspectable**, which is what makes the validator possible.

Two LÖVE facts that constrain this and that Hermes's design ignores:

- `love.filesystem` is sandboxed. `love.filesystem.mount()` takes a `.zip`/`.love` **or a folder inside the save directory** — not an arbitrary OS path. So a "point at a pack folder on disk" dev mode needs either a symlink into the source tree or `io.open` + `love.filesystem.newFileData` + `love.image.newImageData` for images. Decide which now; it's ten lines either way.
- Mounting at a fixed mountpoint (`pack/`) means **every path in the entire codebase is country-agnostic without any of them knowing it**. That's the whole trick.

**Hold IDs, never references.** `npc.home = "muenchen/hofstr_12"`, resolved through `world.place(id)`. If any long-lived object holds a direct pointer into a pack table, hot reload silently keeps the old data alive and you will lose a day to it.

---

## 1.4 Pack format: capabilities are *named*, not *functions* — disagreement with A9

`ARCHITECTURE-FINAL.md` A9 puts `tokenize` and `decompose` in the manifest as Lua functions. I'd change this. Putting functions in the manifest makes the pack code rather than data, which forfeits sandboxing, hot-reload safety, validation, and the ability to ship a data-only pack — and it's a bad home for the actual algorithms, because a Japanese segmenter is five thousand lines and a dictionary, not a manifest field.

**The pack names a capability; the game layer holds the implementation; the pack supplies the data the implementation needs.**

```lua
-- packs/de/pack.lua  — pure data
return {
  id = "de", name = "Deutschland", starting_city = "muenchen",
  currency = "EUR", date_format = "DD.MM.YYYY", decimal = ",",

  language = {
    script       = "latin",
    segmentation = "whitespace_punct",      -- -> game/lexicon/seg/whitespace_punct.lua
    morphology   = { "compound_longest_match" },
    genders      = { "m", "f", "n" },       -- opaque strings; engine never interprets them
    register     = { formal = "Sie", informal = "du" },   -- nil in packs with no T-V
    fugen        = { "s", "n", "en", "es", "er", "e" },   -- linking morphemes: DATA
    no_split     = { "Bahnhof", "Kaufhaus" },             -- exceptions: DATA
  },

  type_roles = {                              -- typography by semantic role, not by name
    street_sign = "fonts/din1451.ttf",
    official    = "fonts/grotesk.ttf",
    handwritten = "fonts/zettel.ttf",
    inscription = "fonts/fraktur.ttf",
    shop        = "fonts/shop.ttf",
  },
}
```

`compound_longest_match` is a **game-layer** algorithm that consults the pack's lexicon (longest-match over known lemmas, `fugen` for the linking `-s-` in `Arbeitsplatz`, `no_split` for the false positives) and defers to any explicit `parts` field on a lexeme. That is the right split: German compound-splitting is not a generic function you can write once — it *needs the lexicon*, which is pack data, and it needs an algorithm, which is code.

If a future pack genuinely needs a new segmenter, that's a game-layer addition, and that's honest. You cannot data-drive a morphological analyzer, and pretending you can is exactly the "grammar rule engine" the doc rightly forbids elsewhere.

Everything else in A9's language block I agree with, including the crucial one: **the German word is the key.** `get_word("bread")` must die, and there's a reason beyond the two the doc gives — acquisition state is a property of a *lexeme*, not of a concept. You know `Semmel` and not `Schrippe`. An English concept key can't represent that, and representing that is the entire game.

One correction to A2's lexicon example: `gloss_en` is a bug. See §1.6.

---

## 1.5 Geometry belongs to the engine, not the pack manifest — disagreement with A9/C1

A9 puts `tile = 16, internal_w = 320, internal_h = 180` in the pack manifest and has the engine "refuse to run on mismatch." C1 then warns that if France arrives at 32px you have two games.

That warning is correct, and it's an argument for the opposite conclusion: **don't make it expressible.**

```lua
-- engine/config.lua  — constants, not configuration
return { TILE = 16, VW = 320, VH = 180, CHAR_W = 16, CHAR_H = 24 }
```

A validated manifest field implies the value can vary, which means every renderer, camera, collision, occlusion, and atlas path gets parameterized on it — and you will never test the other value, so the parameterization is untested indirection that reads as flexibility. Freeze the geometry in the engine and have `tools/validate.lua` check that pack art conforms (atlas dimensions divisible by 16, characters 16×24, etc.). Same guarantee, no false degree of freedom, and about 200 fewer places where `pack.render.tile` appears.

The pack keeps everything that *is* genuinely per-country: palette, LUTs, fonts, atlases, ambient colour keyframes. Those are content. Tile size is geometry.

---

## 1.6 The axis nobody separated: the game's language ≠ the player's language

This is the finding I'd act on first, because it's cheap now and expensive in a year.

`ARCHITECTURE-FINAL.md` A2 writes `gloss_en = "bread (loaf)"` directly into the lexeme record. That silently fuses two orthogonal axes:

| Axis | What it is | Varies by |
|---|---|---|
| **Diegetic language** | The language the *world* speaks. German. | The country pack |
| **UI locale** | The language the *player* reads help, glosses, and settings in. | The player |

Your stated player is someone who moved to Germany. Statistically that person's first language is Turkish, Arabic, Ukrainian, Russian, Romanian, Polish, or Hindi far more often than English. A game whose entire premise is the immigrant experience, shipping glosses in English only, is a design failure and an audience failure — and it is *free* to avoid if you separate the axes now, and a schema migration across every lexeme if you don't.

```
packs/de/lexicon/food.lua      -- { id="Brötchen", gender="n", parts={"Brot","-chen"},
                               --   variants={by="Semmel", berlin="Schrippe"} }   NO gloss
locales/en.lua                 -- gloss = { ["Brötchen"] = "bread roll", ... }
locales/tr.lua                 -- gloss = { ["Brötchen"] = "küçük ekmek", ... }
```

`locales/` sits at the **top level, outside `packs/`**, because it is not a property of Germany. A France pack reuses the same locale files for the same players. And glosses become a translation job you can hand out per language without touching game data — which is the only way it ever gets done.

This also has an art consequence, so decide it before choosing typefaces: **your UI font needs glyph coverage for your target UI locales.** Turkish dotless ı, Polish ł/ż, Ukrainian Cyrillic, Arabic (which additionally needs RTL and shaping, and is where you draw the line for v1). LÖVE's default Vera Sans will not cover this. Pick a UI face with real coverage — Noto Sans, Source Sans, Inter — as a separate decision from the German *signage* faces (DIN, Fraktur), which are pack content and only ever render German.

---

## 1.7 Patterns: exactly what to use, and the discipline that makes each one work

Agreed with A6 on every choice. What A6 omits is the discipline rule that keeps each pattern from becoming the problem it was meant to solve.

| Pattern | Size | The discipline rule that matters |
|---|---|---|
| Plain tables + systems as functions | — | Systems take `(dt, world)` and return nothing. No system owns another system's data. |
| Capability tables (`if npc.shop then`) | — | Capabilities are duck-typed fields, never a class. Never write `NPC:extend()`. |
| Event bus | ~50 | **Events notify; function calls query.** If you need an answer, call. Emitting to ask a question is how event buses become undebuggable. |
| Event queue + single drain | ~15 | Events queue and drain once per frame in registration order. **No emitting during drain** — queue for next frame. Without this, 112 layers produce reentrancy bugs you will never find. |
| Coroutine scheduler | ~60 | One scheduler. Dialogue, cutscenes, NPC routines, *and service calls* all run on it (§1.8). |
| State machines | — | For NPC behaviour and conversation. Not behaviour trees; you have twelve characters, not two hundred. |
| Immediate-mode UI | ~250 | Layout-driven rows/columns, not fixed coordinates — because Germanification changes every label's language and width at runtime (§2.9). |

**No ECS.** ECS solves "thousands of heterogeneous entities with cache-hostile access patterns." You have ~60 entities on a 320×180 screen and twelve characters that matter. ECS would cost you the two things you actually need — legible stack traces and hot reload — in exchange for performance you already have by a factor of a hundred.

The dev-build assertion that makes the bus safe:

```lua
-- game/events.lua — the single registry
local E = {
  ["word.seen"]      = { lexeme="string", source="string" },
  ["word.owned"]     = { lexeme="string", from="string?" },
  ["pfand.returned"] = { count="number", cents="number" },
  -- ...
}
```
Emitting a name not in `E`, or with a payload that doesn't match, is a hard error in dev and a no-op in release. Ten lines. It is the difference between an event bus that scales to 112 layers and one that doesn't.

---

## 1.8 Service hooks: async, awaited on the dialogue scheduler, cancellable

A7's "async from day one" is right. Three things it doesn't specify, all of which are painful retrofits.

**1. The async shape should be `await` on the coroutine scheduler you're already building.** A6 and A7 both exist in the doc and are never connected — connecting them is the whole ergonomic win, because the callers are *always* dialogue coroutines:

```lua
-- inside a dialogue coroutine
local said = await(svc.asr.listen{ expect = "bakery.order", timeout = 6 })
if said.ok and svc.judge.now(said.text, "bakery.order").satisfied then
  play_line("lena.bakery.confirm")
else
  play_line("lena.bakery.pardon")
end
```

`await` yields the coroutine; the scheduler resumes it when the service handle resolves. The v1 ASR stub resolves next frame; the v1 `judge` is Coach's phonetic matcher; the v1 `tts` returns a pre-recorded clip from `packs/de/audio/lines/`. **Not one call site changes** when any of them becomes a real network call, a local LLM, or a hired voice actor.

Callbacks fired from `love.thread` channels would have to be marshalled to the main thread anyway (threads can't touch `love.graphics` and don't share Lua state) — so a single `svc.update(dt)` that drains channels and resumes coroutines is both simpler and the only correct design.

**2. Cancellation and timeout must be in the interface from the first line.** The player walks away mid-conversation while ASR is listening. Every handle needs `:cancel()`, every request needs a timeout, and every `await` needs to be able to return `{ok=false, reason="cancelled"}`. Retrofitting cancellation into a coroutine-based dialogue system is genuinely miserable.

**3. Add `record` / `replay` to the service layer, not to individual services.** Every request/response pair appends to JSONL in the save dir; a replay mode feeds them back deterministically. For a game whose two hardest systems are ASR and (maybe) a local LLM, being able to replay an entire playtest session bit-for-bit is worth an enormous amount and costs about forty lines *if designed in*. It is impossible to add later, because you won't have the recordings.

The interfaces worth stubbing are exactly A7's six (`asr`, `tts`, `content`, `judge`, `telemetry`, `pack_source`), and A7's exclusion list is right — cloud saves, accounts, and a CMS don't thread through gameplay code, so retrofitting them is cheap.

One thing to hold the line on, from `VISION.md`'s own principle: **`content` returns a line ID or a whole authored line. It never composes German from parts.** If an LLM is ever wired in, it *selects* among authored lines or generates content that goes through a human editor offline. The moment a model generates German at runtime, your German-native editor — who the reframe review correctly identifies as the art director of the language layer — is out of the loop, and the world stops being trustworthy.

---

## 1.9 Save system: versioned, migrated, and aware that LÖVE has no `rename`

A10 is right and under-specified. The specifics:

- **Never serialize live tables.** Write an explicit record: `{ version = 7, lexemes = {...}, notebook = {...}, world = {...}, layers = { pfand = {...} } }`. Each gameplay layer serializes its own state under its own key, which is the other reason the layer module shape pays for itself.
- **Migrations are a list of functions**, `m[6] = function(s) ... end`, applied in order. Write the migration in the same commit as the schema change, every time, forever. Games that skip this lose every playtest save at every refactor — and you are planning four years of refactors.
- **Format: dump Lua source for the first two years.** Diffable, greppable, hand-fixable while a tester is on a call with you. Swap to `bitser`/`binser` only if size becomes real (it won't; a full save here is a few hundred KB).
- **LÖVE 11 has no `love.filesystem.rename`, so there is no atomic replace.** Two workable answers: (a) `os.rename` with absolute paths built from `love.filesystem.getSaveDirectory()` — the stock `os` library is available and this is genuinely atomic on both macOS and Windows; or (b) rotate N slot files and write a tiny `current.lua` pointer last. Use (a), fall back to (b). Decide now, because "save corrupted on quit during autosave" is the bug that loses you a tester permanently.

---

## 1.10 The content pipeline **is** the architecture — and it's absent from both documents

`VISION.md` states the risk plainly: *"Content authoring at scale is the real bottleneck, not code."* Neither Hermes nor `ARCHITECTURE-FINAL.md` proposes a single tool for it, and `ARCHITECTURE-FINAL.md`'s 30-day plan has none. This is the largest gap in the current decision record.

**Three tools, in this order of value:**

**1. The reference validator.** Every `line_id`, `lexeme_id`, `screen_id`, `npc_id`, `place_id`, `stamp_id`, `sprite_id` referenced anywhere must resolve. Run it in CI and on load in dev builds. In a four-year project with tens of thousands of content IDs, a dangling reference discovered at runtime in year three — in a branch reached only on a rainy Tuesday in February after a specific conversation — is *the* failure mode. This is the single highest-value tool in `tools/`, it's about 150 lines, and it should exist before the tenth content file.

**2. An authoring format that isn't Lua.** Lua tables are the correct *runtime* format — zero parse cost via `love.filesystem.load`, comments, no dependency. They are a miserable *authoring* format for prose, and worse, they're a miserable format to hand to a German-native editor who is not a programmer. Author lines in a flat text format and compile to Lua:

```
# packs/de/lines_src/lena_bakery.dj
@npc lena  @place baeckerei_hofstr  @register informal

morning.greet [06:40..09:00] [rel>=1]
  Morgen! Na, ausgeschlafen?
  ^ gloss: casual "slept well?" — not a real question
  > player.nod   -> morning.order
  > player.stare -> morning.repeat
```

The compile step (`tools/lines.lua`, ~300 lines) is where you stamp stable IDs, run the validator, extract every German string into a review file for your editor, and diff what changed since their last pass. This turns "get German reviewed" from an impossible perpetual task into a routine diff. It also makes the lines file useful as a script for voice actors, which the reframe review identified as newly viable.

**3. `tools/atlas.lua` and the Tiled adapter.** Tiled exports Lua natively, so the adapter is thin. LÖVE ships no atlas packer, so you write one — or use Aseprite's JSON export and write a 60-line importer, which is better because it also gives you frame tags and animation timing for free.

---

## 1.11 Everything that isn't drawing must be testable without LÖVE

This is the practice that most determines whether a four-year solo LÖVE project stays alive, and neither document mentions it.

LÖVE has no test runner and doesn't run headless comfortably (disabling the window module removes `love.graphics` entirely). So: **inject the filesystem.** `game/pack.lua` takes an `fs` interface with `load`, `exists`, `read`. In LÖVE you pass a `love.filesystem` adapter; in CI you pass an `io`-based one and run under plain `luajit`.

What becomes testable in milliseconds, with no GPU:

- pack loading, manifest validation, capability resolution
- lexicon, acquisition state machine (`unknown → seen → partial → owned`)
- compound decomposition against a fixture lexicon
- text layout box math (font metrics stubbed)
- save migration chains — *every version, every time*, which is how you never lose a save
- all 112 layer modules' pure logic
- the tracer pack (§1.12)

A `tests/` suite that runs in under a second on every commit is the difference between a codebase you can still refactor in year three and one you're afraid of.

---

## 1.12 The tracer pack: adopt it, and make it hostile

A5 is the best original idea in `ARCHITECTURE-FINAL.md` and I'd adopt it verbatim, with a sharper spec. `packs/xx/` should be deliberately, specifically nasty:

- **2 genders**, not 3 — catches anything assuming `{m,f,n}`
- **No `register` field** — catches anything assuming T-V exists
- **`segmentation = "none"`** and `morphology = {}` — catches anything assuming compounds
- **Non-Latin glyphs** in every lemma — smokes out `string.sub`, `#s`, `string.upper` on UTF-8 before those assumptions are load-bearing. `ü` is two bytes; `#"Brötchen"` is 9, not 8.
- **One lemma that is a single combining grapheme cluster** and one that is 47 characters long — catches naive wrapping and naive hyphenation
- **A screen with zero NPCs, and a `places` list with zero shops**
- **No audio directory at all**, and `layers/` containing only one file
- **A locale with no gloss for half the lexemes**

Run it in `tests/`, pure Lua, on every commit. If `xx` breaks, you hardcoded Germany. Pair with A5's CI grep — `! grep -rIn --include=*.lua -P '[äöüßÄÖÜ]|"(Guten|Brot|München)' engine/ game/` — which is the modularity principle mechanized, and is worth more than any interface design.

---

## 1.13 How deep to abstract — the line, and the cost model behind it

The rule: **abstract where retrofitting is *structural*; write it concretely where retrofitting is *textual*.**

Structural = module graph, file paths, ID schemes, save format, text layout, async shape, the event vocabulary. These are spread across hundreds of files and can't be fixed by search-and-replace.

Textual = a string, a constant, a table with three entries. `grep`, replace, done.

| Abstract on day one | Write concretely, extract later |
|---|---|
| Pack mounting + asset resolution (`pack/` prefix) | Number of grammatical genders — opaque strings + a pack article table |
| The layer module shape | T-V distinction — a per-NPC `register` field and authored lines |
| Lexeme store + acquisition state | Dialects — a per-city string→string override table, ~30 lines |
| Line playback (ID → text + optional audio) | Currency, dates, units — one manifest block |
| Text layout returning per-word boxes | Weather — start with rain and snow; generalize when you have five |
| Async service shape + cancellation | Anything named France. `xx` is your France. |
| Save versioning + migrations | Grammar rule engines. Ever. |
| Content ID validation | A quest system — the reframe review is right that there is no quest log |

**The cost of building modular on day one**, stated honestly, because it's real: indirection makes failures late and vague. `require("packs.de.x")` fails at load with a stack trace; `pack.chunk("world/x.lua")` fails at 3am on the Tuesday you finally reach that screen. Mitigate with: loud failure including the full resolution chain and the active pack ID; `P.exists()` checks in dev builds; and the validator, which converts every one of those runtime failures into a CI failure. That mitigation costs a day and removes the entire downside.

**The cost of extracting later** is not the extraction — it's that you'll be doing it at 60k lines, alone, with four years of working software you're afraid to touch, on an axis (countries) you may never actually cross. Which is why the right answer is: build the loader (cheap, structural, high leverage), build the layer module (certain, used 112 times), and build *nothing else* for France.

---

## 1.14 Where I disagree with `ARCHITECTURE-FINAL.md`

Five corrections, ranked by cost of being wrong:

1. **`gloss_en` in the lexeme record (A2).** UI locale is a separate axis from pack language. Move glosses to top-level `locales/`. Wrong now = a schema migration across every lexeme and an English-only product for a non-English audience. *(§1.6)*
2. **Geometry in the pack manifest (A9/C1).** Tile size and internal resolution are engine constants, not validated pack fields. Don't make wrongness expressible. *(§1.5)*
3. **`tokenize`/`decompose` as manifest functions (A9).** Packs are data; capabilities are named; algorithms live in `game/` and consume pack data. *(§1.4)*
4. **No layer module concept anywhere.** The extension axis you'll cross 112 times has no structure, while the one you'll cross twice has three. *(§1.1)*
5. **No content pipeline, no validator, no tests in the 30-day plan (Part D).** The stated #1 project risk has zero architectural response. *(§1.10, §1.11)*

Everything else in Part A I'd sign: three layers, kill `get_word`, loader on day one, tracer pack, no ECS, event bus + coroutine scheduler, async services, versioned saves, and all five LÖVE constraints in A11 — with one refinement to A11's second point, in §2.5.

---

## 1.15 How this interacts with LÖVE2D specifically

| LÖVE strength | Exploit it by |
|---|---|
| No build step, instant iteration | Hot reload of pack data as a first-class feature (§1.3). You'll use it a thousand times. |
| Lua tables *are* the data format | Zero-cost content loading. No JSON parser, no schema compiler, no serialization layer. |
| Tiny API surface | You can hold the whole engine in your head, which is why you don't need ECS or a scene graph. |
| Immediate mode everywhere | UI that reflows when Germanification changes a label's language mid-session. |
| `Canvas:newImageData()` + `ImageData:encode("png", path)` | `Die Kamera` writes **actual PNGs into the save directory**. The player's photo book is real files they can find on disk. That's a free, delightful, entirely diegetic feature. |

| LÖVE limitation | The design response |
|---|---|
| Sandboxed filesystem | The mountpoint trick (§1.3). Also your DLC path. |
| No asset pipeline | Budget `tools/` from day one. It is not optional. |
| No test runner, awkward headless | Pure-Lua core with an injected fs (§1.11). |
| Threads don't share Lua state | Keep the Coach sidecar over UDP. Use threads for disk I/O, audio decode, telemetry — never game logic. |
| LuaJIT GC pauses under allocation churn | **Cache text layout; never rebuild word boxes per frame.** This is your one real perf trap — the veil runs on every visible string. Layout on change, draw from cache. `require("table.new")`/`table.clear` are available in LÖVE's LuaJIT 2.1 for the hot caches. |
| `love.graphics.setColor` is 0–1 floats since 11.0 | Every lighting/shader tutorial older than 11.0 is wrong by 255×. Target 11.5 (agreed with A11 — do not design around 12). |

---

# PART 2 — ART DIRECTION

## 2.0 Verdict

**Approach B.** One pixel-art pipeline. **Ship "modern" as the game.** Retro is a *pipeline branch*, not a design language you balance around.

16×16 tiles, 320×180 internal, nearest filtering always, locked 32–48 colour authoring palette, frame-by-frame animation, four directions, UI at device resolution on a separate layer.

`ARCHITECTURE-FINAL.md` Part B gets all of this right. Where I diverge is in three places that will actually change what you build: the retro branch's position in the pipeline (§2.2), **the diegetic-text problem, which is unsolved and conflicts with your own Prototype 1** (§2.5), and the art-hours multiplier nobody has proposed (§2.8).

---

## 2.1 Approach A is wrong, and it's worth naming why it was asked for

Approach A — two asset sets — is not "twice the art." It is **two design languages**, permanently. Every screen must compose in both. Every readability judgement must hold in both. Every new prop is drawn twice, palette-checked twice, and reviewed twice. That's a ~1.6× tax on every visual decision for a solo developer whose critical path *is* art, in service of a settings toggle almost nobody flips twice.

And there's a specific reason it's worse here than in a normal game: **your game is about reading.** A four-shade Game Boy palette with a 5×7 font cannot express "this Bürgeramt letter looks hard" versus "this bakery price list looks easy" — and the reframe review correctly identifies that typography-and-density-as-difficulty-signal is one of the best free mechanics in the design. Retro mode doesn't just cost art hours; it deletes a mechanic.

The honest read: asking for two options is a hedge against not being able to execute "modern." The right answer to that hedge isn't two pipelines — it's **§2.12, the week-one drawing spike**, which answers the question for the cost of three days instead of three years.

---

## 2.2 Retro must be a pipeline *branch*, not a post-filter — disagreement with B1

`ARCHITECTURE-FINAL.md` B1 says retro is "a full-screen CRT/Game-Boy post-pass" on the composited frame. Technically, that will look bad, and it's worth knowing why before you build it.

Quantizing a frame that has already been lit, colour-graded, and bloomed doesn't produce nostalgia — it produces **banding**. The characteristic look of 8-bit art comes from *flat regions of exact palette colours with hand-placed dither*. A smooth radial light gradient quantized to four shades produces concentric rings, which is precisely the artifact real Game Boy artists worked to avoid.

So the retro path is a branch taken *before* lighting:

```lua
function render.frame()
  gfx.push_canvas(albedo); world.draw(); gfx.pop()

  if mode == "retro" then
    gfx.push_canvas(scene)
      gfx.draw(albedo)
      gfx.shader(sh.retro, { palette = retro_lut, dither = bayer8, level = 4 })
    gfx.pop()
  else
    lights.draw(light_canvas)                    -- additive, ambient-cleared
    gfx.composite(scene, albedo, light_canvas, emissive)
    gfx.grade(scene, lut_now, lut_next, blend)   -- day/night + per-city
    gfx.bloom(scene)
    gfx.vignette(scene)
  end

  present.integer_scale_letterbox(scene)         -- identical for both
end
```

One boolean, two branches, one shared presenter. Still near-zero design tax and near-zero art cost — B1's conclusion is right — but the *implementation* has to skip the modern stack rather than sit on top of it.

Two specifics for the retro shader: apply **ordered Bayer dithering (8×8) at the internal resolution, before upscale** — dithering after upscale looks like a screen-door, dithering before looks like a Game Boy. And apply the scanline/LCD-grid in the *presenter*, at output resolution, since that's a display artifact, not a scene artifact.

Frame it diegetically if you want — a handheld the character owns, a `Fotomodus` filter for `Die Kamera`. What it isn't is a mode you balance the game around. If the founder insists on two genuine modes, verify retro at exactly three checkpoints (signage legibility, NPC silhouette distinguishability, veil stratification) and never screen-by-screen.

---

## 2.3 Feasibility and the modern stack, in build order

Yes, Approach B is comfortably feasible in LÖVE 11.5. B11's capability table is accurate. The concrete stack, ordered by value per line:

**Tier 1 — build in the first month.**

**1. Fixed canvas + integer scale + letterbox.** Must exist before the first tile.

**2. Day/night grading via LUT.** Highest value-per-line effect in the entire stack, ~30 lines. A 256×16 neutral-LUT strip PNG per time-of-day keyframe, cross-faded in a full-screen shader.

Three gotchas that will each cost you an afternoon:
- With `setDefaultFilter("nearest")` global, you **must** explicitly `lut:setFilter("linear","linear")` or every colour snaps to 16 buckets.
- `lut:setWrap("clamp","clamp")`, and offset your slice sampling by half a texel, or you get magenta fringing at slice boundaries.
- Cross-fade by sampling *both* LUTs and `mix()`ing the results — never by lerping the LUT coordinates.

**3. The 2D light pass — and lights are *sprites*, not math.**

The instinct is to write a radial-falloff shader with per-light uniforms. Don't. Author each light as a small PNG (a radial gradient, a rectangular window-spill, a cone, a shaped Durchgang shaft), draw it additively into a light canvas cleared to the ambient colour, and composite `albedo × light + emissive`. At 320×180 with thirty lights this is faster than a shader loop, it's one draw call each, and — the real reason — **it gives you hand-authored control over light shape**, which is what makes a shop window spilling a rectangle of warm light onto wet pavement look drawn rather than computed. For a hand-authored game this is strictly better than correctness.

The one LÖVE bug everybody hits: `setBlendMode("multiply")` **requires** premultiplied alpha, and drawing a Canvas you rendered to should use `setBlendMode("alpha", "premultiplied")` or you double-multiply and everything is too dark at the edges.

**4. Foreground occlusion with alpha fade.** B4 is right that top-down has no horizon and therefore no parallax. Occlusion is the correct substitute *and it's the better one for this game specifically*, because the reframe review names the Durchgang/Hinterhof/courtyard-behind-courtyard reveal as a top-five exploration attractor. Implementation: a per-screen `over` layer, drawn after entities; when the player's collision box intersects an occluder's footprint, lerp that occluder's alpha to ~0.35 over 150ms. Per-occluder, not per-layer.

One place parallax *does* belong, since Hermes wasn't entirely wrong: **windows and vehicles.** The view through an S-Bahn window, a passing tram's interior, the view from a Hochhaus stairwell. Scrolling layers inside a bounded rectangle. That's a genuinely lovely effect and it's a different system from world parallax.

**Tier 2 — after Tier 1 looks good.**

**5. Bloom** on `rgba16f` (bright-pass → half-res downsample → separable gaussian → add). Keep it subtle. At 320×180 the ping-pong canvases are ~460KB each; VRAM is a non-issue.

**6. Weather.** Rain as a screen-space scrolling texture at internal resolution *inside* the world canvas (so lights illuminate it), plus a `ParticleSystem` for splashes. Snow accumulation as tile-variant swap. And the one that pays for the whole system:

**7. Puddle reflections.** Draw the scene canvas again, flipped vertically with a small Y offset, masked by a per-screen puddle mask, at ~0.3 alpha with a horizontal sine distortion in the shader. Twenty lines. A rainy German street with reflections in it is the screenshot.

**Tier 3 — only if the game is already good.** Skip normal maps entirely (B5 is right — hand-authoring normals at your scale costs more than baked directional shading plus a contact shadow returns). Screen shake, never on text.

Skip 2D shadow casting. Hand-authored contact shadows (a soft ellipse under each entity) plus ambient occlusion painted into the tiles gets you 95% at 1% of the cost, and it's *art*, which is the thing you control.

---

## 2.4 Resolution and tile size: 320×180 at 16px, confirmed — plus two traps

B2's reasoning is right and the arithmetic confirms it: 320×180 integer-scales to 720p (×4), 1080p (×6), 1440p (×8), and 4K (×12). The alternative, 384×216, gives more field of view and hits 1080p (×5) and 4K (×10) but misses 720p entirely. 320×180 is the better citizen. Take it and never change it.

16×16 over 32×32, for the reason that matters most here: **prop count beats prop detail, and your world's entire value proposition is density of specific named things** — Litfaßsäule, Packstation, gelbe Post, Stolperstein, Pfandautomat, Klingelschild, Ampelmännchen, Bierkasten, Sperrmüll. A 16px prop is roughly 4× the distinct objects per drawing hour. Field of view seals it: 20×11 tiles is a legible chunk of street; 10×5.6 is a corridor.

Characters 16 wide × 24–32 tall, four directions, sub-tile prop placement allowed. Portraits at 48×48 or 64×64 beside dialogue — that's how you get facial expression without upgrading every tile in the game.

**Two traps neither document mentions, both of which will bite in week one:**

**Retina/DPI.** The founder is on an M4 Mac. With `t.window.highdpi = true`, the drawable surface is 2× the reported window size, and your integer scale factor must be computed from `love.graphics.getWidth() * love.window.getDPIScale()`. Get this wrong and your "integer-scaled" pixel art is scaled by 3.5 and shimmers. Decide it in `conf.lua` on day one.

**Sub-pixel camera shimmer.** If the camera translates by a non-integer amount, every sprite resamples differently each frame and the whole screen crawls. **Round the camera translation to whole internal pixels** before drawing (`math.floor(cam.x + 0.5)`). At 6× output scale, integer stepping at 60fps is perfectly smooth. If you later want true sub-pixel scrolling, do it by offsetting the *presentation* of the finished canvas by a fraction of the output scale — never by moving the world.

And: **never change the internal resolution to zoom.** The notebook map, the Aushang close-up, and the letter are separate *screens* drawn as pages, not zoomed cameras. The instant you allow a zoom factor, integer scaling is gone.

---

## 2.5 The unsolved problem: diegetic text — and it breaks Prototype 1

This is my most important art-side finding, and it's a direct conflict between two decisions already made.

`ARCHITECTURE-FINAL.md` B8 says: *"Diegetic text on signs stays in the pixel layer (it's world)."*

The reframe review's Prototype 1 (`Der Block`, adopted in Part D as the critical path) says the German content is: *"environmental only — shop signs, Klingelschilder, an Aushang board, a window menu, opening hours, a Pfand machine, a ticket machine, graffiti, a Stolperstein, a 'Zu vermieten' sign."*

At 320×180, a shop sign is roughly 32×10 pixels. `Bäckerei Rischart` is sixteen characters. You cannot render it. **Your first prototype's entire content is text that your rendering spec makes illegible.**

The resolution is a three-tier text model, and it changes the renderer's structure, so it has to be decided now.

| Tier | What | Where it renders | Example |
|---|---|---|---|
| **1 — Texture** | The *shape* of writing. Illegible, characteristic. | Baked into tiles, pixel layer | A green Apotheke cross, a shop fascia with sign-shaped marks, dense grey blocks on a noticeboard |
| **2 — Focus** | Readable, real typography, on demand | UI layer at device resolution, in a framed panel | Standing at the Aushang lifts it into a readable board. `Was ist das?` on a Klingelschild opens the nameplate. Reading a letter opens the letter. |
| **3 — Wayfinding** | Always crisp, always legible, in world space | **Device resolution, world-anchored** | Street name plates, platform numbers, house numbers, U-Bahn line letters, exit signs |

Tier 3 is the one that changes your architecture. The reframe review made "never veil wayfinding" a design law, and you cannot honour that law with 16px pixel text. So the renderer needs a pass that **draws text at device resolution using world coordinates**, after the scaled canvas is presented:

```lua
-- after present.integer_scale_letterbox(scene)
local s, ox, oy = present.transform()          -- integer scale + letterbox offsets
for _, t in ipairs(world.visible_texts(cam)) do
  local x = (t.wx - cam.x) * s + ox
  local y = (t.wy - cam.y) * s + oy
  ui.text(t.role, t.string, x, y, s)           -- role -> pack typeface, size scaled by s
end
```

Forty lines. It must exist from Prototype 1, and it has three consequences worth accepting deliberately:

1. **The `project(world → device)` function becomes a shared primitive** used by wayfinding text, focus panels, NPC name labels, notebook pins, and interaction prompts. Write it once, in `engine/`.
2. **Typography is pack content, keyed by semantic role** (§1.4's `type_roles`) — `street_sign` → DIN 1451, `inscription` → Fraktur, `handwritten` → a Zettel face, `official` → a grotesque. France maps the same roles to different faces. This is exactly the same shape as the layer-capability pattern, which is a good sign it's the right abstraction.
3. **German signage typography *is* the art direction**, and it costs font licensing rather than drawing hours — which is precisely the trade a non-artist should be making. Nothing says "this is Germany" faster than DIN on a blue sign. *(Verify redistribution rights per face; there are open DIN-derivatives and free Fraktur options. Check them before you get attached.)*

**A correction to A11's second constraint.** It says `love.graphics.print` "can't style per word, you need to lay out words yourself." Half right, and the half it misses is useful: LÖVE 11 supports **coloured text tables** — `love.graphics.print({{1,1,1,1}, "Ich hätte gern ", {1,1,1,0.35}, "Brötchen"}, x, y)` — including through `printf` with wrapping. So per-fragment *colour and alpha* with correct wrapping is free, which is exactly what the veil needs. What you still must build yourself is **per-word hitboxes**, because click-a-word-to-notebook and `Was ist das?` are core verbs. Do both: your layout pass computes boxes; your draw pass emits one coloured-text table per line, so you get hitboxes *and* batched drawing.

**And the German-specific one nobody has raised: line breaking.** LÖVE's wrapper breaks on spaces and hard-breaks an over-long word at whatever character overflows. `Rindfleischetikettierungsüberwachungsaufgabenübertragungsgesetz` will break mid-morpheme, which looks broken in a way German readers notice immediately. The fix is elegant: **your lexicon's `parts` field is already a hyphenation dictionary.** `Hand|schuh`. `Kranken|haus`. The same data drives `Wortzerlegung`, focus-text hyphenation, and notebook wrapping. Design that field once, carefully — it has three consumers.

---

## 2.6 The palette question: you need three colour artifacts, not one

B7 says "lock 32–48 colours and never leave it." Correct, and the most effective single crutch available to a developer with limited art skills — it makes assets drawn eight months apart look like one game. But B7 and B5 quietly conflict: if you lock a palette and then apply a light pass, a per-city LUT, and bloom, the output frame is *not* in the palette. That's fine and good — but it means you have three distinct colour artifacts doing three distinct jobs, and conflating them produces confusion later:

| Artifact | Job | Where |
|---|---|---|
| **Master palette (32–48)** | Authoring constraint. Coherence across four years of drawing. | Aseprite, source PNGs, the linter |
| **Grading LUTs (arbitrary output)** | Time of day, weather, per-city atmosphere. Munich warm, Berlin grey, Hamburg cold-blue. | Pack, applied post-lighting |
| **Retro LUT (4 or 16)** | The retro branch's quantization target | Pack, applied pre-lighting |

Three refinements:

- **Enforce the palette at the drawing tool, not the linter.** Work in Aseprite's **indexed colour mode** with the master palette loaded — then drawing off-palette is *impossible* rather than *caught later*. `tools/palette_check.lua` becomes a backstop for imported and commissioned art, which is where violations actually come from.
- **Reserve 3–4 slots used nowhere in the world**, only for interactable highlighting and veil-state emphasis. Things pop without an outline shader, and it costs nothing.
- **Regional atmosphere at the LUT stage, never the asset stage** (B7 is right). Munich and Berlin share every tile and differ by one 8KB PNG. This is the single largest art-hours saving in the entire art direction.

---

## 2.7 Animation: frame-by-frame, plus two techniques worth more than more frames

Frame-by-frame at runtime — agreed, unanimously and correctly. Skeletal deformation at 16×24 produces sub-pixel rotation, which is mush. The *offline* pipeline is open: Blender orthographic render → palette quantize → hand-clean is viable for a non-artist and is what Dead Cells does.

Budget: **4 directions (not 8), 4-frame walk, 2-frame idle, 2-frame interact = 8 poses per character.** Eight-directional movement doubles art cost and top-down streets read fine at four.

Two techniques that beat spending the hours on more character frames:

**1. Animated tiles, mutated in place.** `SpriteBatch:set(index, quad, x, y)` rewrites one sprite in an existing batch. A per-tile frame list from Tiled, a timer, and one `:set` call per animated tile per frame gives you two hundred animated tiles for free: the Pfandautomat's LED cycle, a TV flickering through a window, a rotating Döner spit, the U-Bahn departure board, a traffic light, a laundry line. This is where "the world is alive" actually comes from, and it costs nothing per frame.

**2. `love.graphics.newMesh` for cloth.** A flapping Aushang on a lamppost, a café awning, laundry on a line, tram catenary, a flag, a plastic bag. A 4×4 vertex grid with a sine offset per frame — twenty lines, and it produces motion that frame-by-frame would cost days. The nearest-filtered wobble reads as *fabric*, not as an artifact, and the reframe review names the Aushang as your entire quest-giving system.

Spend the rest of the animation budget on the world, exactly as B6 says: steam from a Dönerbude, a tram passing, a roller shutter, the Kehrmaschine at 07:00.

---

## 2.8 The art-hours multiplier nobody has proposed: facade kits

The binding question is *"can one person draw a German city?"* Drawn tile by tile, the answer is no — 40–60 screens of Gründerzeit facades is thousands of hours.

But German built form is **modular in reality**. A facade is: a ground-floor shop front, a repeating window unit, an occasional balcony, a door, a cornice, a roofline. Build a *kit*, not tiles:

```lua
-- packs/de/art/facades/gruenderzeit.lua
{ ground = {"shop_a","shop_b","shop_c","door_1","door_2"},
  window = {"w_tall","w_tall_shutter","w_arched","w_boarded","w_flowers","w_satdish"},
  band   = {"cornice_a","cornice_b"},
  roof   = {"mansard","flat","dormer"},
  wall   = {"stucco_ochre","stucco_grey","brick_red","plattenbau_panel"} }
```

20 window variants × 8 wall colours × 6 door types × 4 rooflines composes hundreds of distinct, plausible buildings from about forty drawings. Compose deterministically from a seed stored in the screen data, render **once** into a Canvas at load, and treat the result as a single static sprite — one draw call, and it's hand-overridable where a specific building matters (the bakery, the Bürgeramt, your flat).

This is the highest-leverage art decision available for this specific game, and it's specific to *this* game because German cities are unusually regular in their vocabulary and unusually varied in their combination — which is exactly what a kit captures and what hand-drawn tiles don't.

Then: **spend every remaining hour on the specific props nobody sells.** B12 is right that the specificity *is* the art direction. A generic street with a correct Litfaßsäule, a correct Packstation, a correct yellow Post box, and a correct Pfandautomat reads as Germany. A beautifully drawn street without them reads as anywhere.

---

## 2.9 UI: separate layer, device resolution, no toggle

B8 is right, emphatically, and it's the best call in Part B. Your game is about reading German; a 5×7 pixel font at 320×180 cannot render Fraktur, cannot render a Bürgeramt letter, and cannot express the difficulty-through-typography signal that is one of your best free mechanics.

The implementation rules:

- **Two canvases, two coordinate systems, one bridge.** World renders to 320×180 and is presented scaled. UI draws at device resolution on top. The *only* thing crossing is `project(world → device)` (§2.5).
- **Fonts are created at device pixel size** — `love.graphics.newFont(path, size, hinting, dpiscale)` — and rebuilt on window resize. Cache by `(role, device_px)`. Use `"mono"` or `"none"` hinting for small crisp UI text; the default hinting softens small sizes in a way that fights a pixel-art game.
- **The UI must be layout-driven, not fixed-coordinate.** This is *why* retained-mode Lua GUI libraries fail here, and the reason is specific to your game: **Germanification changes every label's language at runtime.** `Inventory` → `Inventar` → `Rucksack` are three different widths. If your UI has coordinates in it, every Germanification event is a visual bug. Immediate-mode with a row/column layouter, ~250 lines.
- **The label primitive is the thing to get right on day one**, because everything uses it:

```lua
-- three states per label, driven by the mechanic and the player's locale
-- 1. locale text (early)   2. German (Germanified)   3. German + hover gloss (transitional)
ui.label("menu.inventory")   -- resolves via germanification state + locale + pack ui strings
```

Getting this wrong means touching every screen later. Getting it right means Germanification is one function.

**Der Schleier in the UI layer.** Alpha stratification by acquisition state, exactly as B9 specifies — zero shaders, no wobble, no scramble, always crisp glyphs. Three additions:

1. **Layout must be computed from the text alone, never from the style.** A word transitioning `seen → owned` must not reflow the paragraph, or the player watches sentences twitch. Practical rule: identical font, size, and tracking across all four states; **only colour and alpha vary.** The moment you want bold-for-owned, layout stability is gone.
2. **Alpha alone is insufficient.** It's invisible to a colourblind player and illegible on a bright background. Add a redundant channel: a dotted underline for `unknown`, thin for `seen`, none for `owned`. Accessible, and it also solves 35% alpha ink on a pale Aushang.
3. **Cache the layout.** This runs on every visible string, every frame. Compute boxes on change; draw from cache. This is the LuaJIT allocation trap from §1.15, and it's the one place in this game where performance is genuinely at risk.

---

## 2.10 How art direction couples to the core mechanics

**Der Schleier / comprehension.** Text layout, not shaders (B9 is right, and the reframe review's islands model is right). Two things that follow: the veil lives in `game/`, not `engine/gfx/`, because it's country-agnostic and pack-fed; and it works identically in the retro branch, because it's ink, not effects.

**Day/night — and the coupling nobody has designed.** Germany's legally-mandated rhythm (Ladenschluss, Ruhezeit, Sonntag, Feiertage) is both your content-gating system and your lighting system. **A lit window means open.** Which means the emissive canvas and the interaction system must read from *one* source:

```lua
world.is_open(place_id, clock.now())   -- consumed by: the light pass AND the door
```

If they ever diverge, the world lies to the player — a lit bakery you can't enter is a bug the player experiences as a broken world, not a graphics glitch. Design this as one function with two consumers from the first screen.

**Sunday** becomes a rendering event for free: fewer NPCs on their schedules, fewer emissive windows, a colder ambient LUT, church bells, and the Kehrmaschine absent. The reframe review calls Sunday the most characterful day in the German week and notes nobody mentioned it. It costs you a LUT and a schedule flag.

**Weather.** Rain inside the world canvas so lights catch it; puddle reflections keyed to a per-screen mask; snow as tile-variant swap. Weather is also a `game/` layer that emits `weather.changed`, which the clothing system, the NPC schedule (people go inside), the ambient audio, and the light pass all subscribe to. That's the event bus earning its forty lines.

**`Die Kamera`.** `Canvas:newImageData()` → `ImageData:encode("png", "photos/2026-08-13-marienplatz.png")` writes into the save directory. The photo book is real files. Apply the retro LUT as a `Fotomodus` filter and you've given the retro mode a diegetic home that costs nothing and is genuinely charming.

---

## 2.11 Other approaches, honestly weighed

- **Flat vector / limited-shape** (Kentucky Route Zero, Carto). Genuinely viable in LÖVE and far more forgiving for a non-artist. Keep as the month-six pivot if pixel art isn't working. It also solves the diegetic-text problem outright, since everything renders at device resolution.
- **Photo-derived pixel art.** Photograph a Munich block, downsample hard, quantize to the master palette, hand-clean. Worth **one day** as an experiment because it directly answers "can you make a screen someone would screenshot" for almost nothing. Watch the trap: photo-derived art has correct *values* and no *silhouette*, so it reads as mush at 16px unless you re-draw the shapes.
- **Blender orthographic → pixelize** (the Dead Cells pipeline). Best fit for the **facade kit** (§2.8) and for vehicles — a tram, a DB regional train, a Golf — which are hard to draw and easy to model. Not for characters, where hand pixels beat rendered ones at 16×24.
- **Hand-drawn / painterly, ink-and-wash.** Fits the notebook, the letters, and the Aushang *beautifully* as a UI-layer treatment even if the world is pixels. Consider a hybrid: pixel world, hand-drawn paper. The contrast would be striking and it plays to prose-and-paper strengths.
- **Claymation / photographic collage / 3D.** No. Each is a full pipeline with no fallback and no relationship to LÖVE's strengths.

Reference set: keep Dead Cells, Hyper Light Drifter, Celeste. **Drop Octopath Traveler** — HD-2D is sprites in a real 3D scene with perspective and volumetric light; chasing it in LÖVE means writing a 3D renderer. **Add Eastward** (the gold standard for dense, warm, readable *urban* pixel art with modern lighting — much closer to your subject) and **Kentucky Route Zero** (one-screen-one-idea composition, dramatic light, and your fallback).

---

## 2.12 The practical path for a solo developer with limited art skills

1. **Draw one screen before you write any engine code.** Three days in Aseprite: one German street corner, 320×180, 16px tiles, a locked palette, one Litfaßsäule, one bakery with a lit window, one Klingelschild panel, one Aushang. Show it to five people. This answers the binding question of the entire project — the reframe review names it, and `ARCHITECTURE-FINAL.md`'s build plan puts it at position 9 with the note "the rest of forever." **That ordering is backwards.** If you can't make a screen someone wants to look at, you want to know in week one, not month seven.
2. **Fix palette and resolution before drawing anything.** Indexed mode in Aseprite, master palette loaded.
3. **License a base urban 16px tileset as substrate**, then spend every hour on the German-specific props nobody sells. The generic tiles are ground; the specificity is the art direction.
4. **Build the facade kit** (§2.8) before drawing the second screen.
5. **Learn exactly one skill: value structure.** Squint at every screen. If shapes don't read in greyscale, colour won't save them.
6. **Use photo reference relentlessly.** Photograph the actual block you're modelling. Trace silhouettes at 16px.
7. **Commission the twelve characters and portraits once**, after the game is proven. "12 characters × 8 poses + 12 portraits, this palette, 16×24, 4-directional" is a well-defined, quotable job.
8. **Never mix pixel densities**, except the one deliberate UI layer.

---

# PART 3 — WHERE THE TWO DECISIONS COLLIDE

**C1. Geometry is engine, content is pack.** Tile size, internal resolution, atlas format, and the emissive convention are engine constants (§1.5). Palette, LUTs, fonts, atlases, and ambient keyframes are pack content. The validator enforces conformance; the manifest doesn't offer the choice.

**C2. Typography is pack content, keyed by role, and it's code-adjacent.** `type_roles` maps `street_sign`/`official`/`handwritten`/`inscription` to faces. France maps the same roles to different faces with zero code change. Japan needs a different *text engine* — vertical writing, ruby, CJK line breaking, 2000+ glyphs — which is a game-layer addition, not a pack. The thing to do now isn't to build for that; it's to **not bake in `string.sub`, LTR-only assumptions, or space-delimited splitting**. Segmentation is a named capability from day one (§1.4). That's the whole of the insurance.

**C3. The lexeme's `parts` field has three consumers.** `Wortzerlegung` (the mechanic), German hyphenation in focus text (§2.5), and the compound-splitting analyzer. One field, designed once, carefully. Get it wrong and you fix it in three places across thousands of entries.

**C4. `world.is_open()` has two consumers** — the light pass and the interaction system (§2.10). One function. If they diverge, the world lies.

**C5. 112 layers means 112 prop sets, so atlas per domain, not one atlas.** Adding the Imkerei layer adds `packs/de/art/props/imkerei.png` and `packs/de/layers/imkerei.lua` and touches nothing else. One giant atlas means every layer addition is a repack and a merge conflict with yourself.

**C6. UI locale is an art decision as well as an architecture one.** Your UI font must cover Turkish, Polish, Ukrainian, and Romanian if you mean the localization axis seriously (§1.6). Decide this before you fall in love with a typeface.

**C7. Prototype 1 settles both decisions empirically.** `Der Block` — 6–9 screens, no dialogue — needs the presenter, palette, tile size, occlusion layer, day/night LUT, world-space text pass, positional audio, the pack loader, and the tracer pack. Nothing else. Build it with the loader and `xx` in place from the first commit and you answer Decision 1 with running code while answering the only question that matters for Decision 2.

---

# PART 4 — REVISED FIRST 30 DAYS

The change from `ARCHITECTURE-FINAL.md` Part D: the art spike moves to day one, and the content pipeline and test harness appear at all.

| # | Task | Est. | Why here |
|---|---|---|---|
| 0 | **Draw one screen in Aseprite. No code.** 320×180, 16px, locked palette, one bakery, one Aushang, one Litfaßsäule. Show five people. | 3 d | The binding question of the project. Answer it before spending 30 days on a renderer for art that doesn't work. |
| 1 | `conf.lua` + 320×180 canvas + integer scale + letterbox + **DPI handling** | 1 d | Unrecoverable later |
| 2 | Pack loader (`love.filesystem.load` + `setfenv` + mountpoint) + `packs/de/pack.lua` + `packs/xx/` tracer + pure-Lua fs shim + CI grep | 2 d | Structural; brutal to retrofit |
| 3 | `tests/` running under plain luajit, with the tracer pack green | 1 d | Everything after this is protected |
| 4 | Event bus (queued, single drain, declared registry) + coroutine scheduler + `await` | 1.5 d | The two highest-leverage files in the project |
| 5 | **Layer module shape + registry**, with `pfand` as the first instance | 1.5 d | The axis you cross 112 times |
| 6 | Tiled → Lua, SpriteBatch layers, Y-sort, **foreground occlusion with alpha fade**, animated tiles | 4 d | The world renderer |
| 7 | Palette lock (Aseprite indexed) + off-palette linter | 0.5 d | Cheap guardrail |
| 8 | Clock/calendar + LUT grading + light-sprites pass + emissive + `world.is_open()` | 4 d | Highest value-per-line visual work |
| 9 | **Text layout returning word boxes + acquisition styling + world-space device-res text pass** | 4 d | The mechanic is a text-layout problem. Before any dialogue system. |
| 10 | `tools/validate.lua` — reference integrity across all content IDs | 1.5 d | The tool that saves year three |
| 11 | Positional ambient audio (mono sources) + one working sound cone + EFX reverb in a Durchgang | 2 d | The reframe review ranks sound above visuals as an attractor |
| 12 | Save: versioned record, migration list, `os.rename` atomic write | 1 d | Before the first playtest, not after |
| 13 | `tools/lines.lua` — authoring format → compiled Lua + editor review extract | 2 d | The #1 stated project risk |
| 14 | Draw the block | forever |

Item 9 before any dialogue system is deliberate and I'd hold that line hard — the veil is the mechanic, and the mechanic is layout.

---

# PART 5 — SCORECARD

### Versus Hermes

| Point | Hermes | My position |
|---|---|---|
| Data-driven, not framework-driven | ✅ | **Agree** — the single most important shared instinct |
| No plugin system / DI / config tooling | ✅ | **Agree** |
| `data.language.word("bread")` | Proposes | **Disagree — kill it.** German is the key. Beyond the interlingua problem: acquisition state is a property of a lexeme, not a concept. You know `Semmel` and not `Schrippe`. |
| Two layers (engine/data) | Proposes | **Disagree — three**, plus a layer-module unit inside `game/` |
| Don't build a pack loader yet | Proposes | **Disagree.** `require("packs.de.x")` puts Germany in the module graph — the one genuinely brutal retrofit |
| Synchronous swappable service functions | Proposes | **Disagree — async, awaited, cancellable from day one** |
| Approach B, one pipeline two modes | ✅ | **Agree**, and go further: ship modern, branch for retro |
| 32×32 tiles | Proposes | **Disagree — 16×16.** Prop count beats prop detail, and density of named things is the product |
| Linear filtering in modern mode | Proposes | **Disagree — nearest always.** Linear on pixel art at non-integer scale is mush, not modernity |
| Parallax layers | Proposes | **Disagree for the world** (no horizon in top-down); **agree for windows and vehicles**, which is a lovely separate effect |
| Frame-by-frame animation | ✅ | **Agree**, plus mesh cloth and animated tiles |
| UI follows the retro/modern toggle | Proposes | **Disagree — UI is a separate device-resolution layer and does not toggle.** Typography is a mechanic |
| "Blur when confused" | Proposes | **Disagree — islands, zero shaders.** Blur is not what incomprehension feels like, and it obstructs reading, which is the game |
| Art lives in the country pack | ✅ | **Agree**, with geometry hoisted to the engine |

### Versus `ARCHITECTURE-FINAL.md`

| Point | FINAL | My position |
|---|---|---|
| Three layers | ✅ | **Agree** |
| Kill `get_word` | ✅ | **Agree**, with an added reason |
| Pack loader day one | ✅ | **Agree** — plus load pack Lua as sandboxed data, never `require` |
| Tracer pack `packs/xx/` | ✅ | **Agree** — best original idea in the doc. Make it hostile (§1.12) |
| No ECS; bus + scheduler | ✅ | **Agree** — add queue/drain discipline and a declared event registry |
| Async services | ✅ | **Agree** — add `await` on the same scheduler, cancellation, record/replay |
| Versioned saves + migrations | ✅ | **Agree** — note LÖVE has no `rename` |
| `render` block in the manifest, engine validates | Proposes | **Disagree — engine constants.** Don't make wrongness expressible |
| `tokenize`/`decompose` as manifest functions | Proposes | **Disagree — named capabilities + pack data; algorithms in `game/`** |
| `gloss_en` on the lexeme | Proposes | **Disagree — UI locale is a separate axis.** `locales/` outside `packs/`. Your audience is not English-first |
| Layer modularity | *Absent* | **Add it.** 112 layers is the certain axis; countries are the speculative one |
| Content pipeline / validator / tests | *Absent* | **Add all three.** The stated #1 risk has no architectural response |
| Approach B, ship modern, retro as filter | ✅ | **Agree on the decision; correct the implementation** — a branch before lighting, not a post-pass after it |
| 16×16 at 320×180, nearest always | ✅ | **Agree** — add DPI handling and integer camera rounding |
| Foreground occlusion over parallax | ✅ | **Agree** |
| LUT grading, light pass, emissive | ✅ | **Agree** — and make lights *sprites*, not shader math |
| 32–48 locked palette, regional at LUT stage | ✅ | **Agree** — enforce in Aseprite indexed mode; separate the three colour artifacts |
| UI at device resolution, no toggle | ✅ | **Agree** — strongest call in Part B |
| Veil = islands, zero shaders | ✅ | **Agree** — add layout stability and a redundant non-alpha channel |
| "Diegetic sign text stays in the pixel layer" | Proposes | **Disagree — it's illegible at 16px and it is Prototype 1's entire content.** Three text tiers + a world-space device-resolution pass (§2.5) |
| Build order: draw the block last | Proposes | **Disagree — the art spike is day one.** Three days answers the project's binding question |

---

## The three things to change first

1. **Move glosses out of the lexeme and into `locales/`, outside `packs/`.** Cheapest fix on this list today, a schema migration across every entry in six months, and it decides whether a Turkish speaker who moved to Berlin can play your game.

2. **Decide the diegetic-text model before the first tile.** Three tiers, and a world-space device-resolution text pass in the renderer from Prototype 1. Your first prototype's entire content is environmental German that the current art spec cannot render.

3. **Make the gameplay layer a first-class module, and draw a screen before you write the engine.** The first makes 112 layers cost a day each instead of a week. The second tells you in three days whether any of it is worth building.

---

*This review disagrees with `ARCHITECTURE-FINAL.md` in five places on architecture and three on art. Everything else in that document I'd sign as written — it is a genuinely good decision record, and the disagreements above are refinements to it, not a replacement for it.*

---

The file `docs/reviews/claude-architecture-review-2026-08-12.md` is still 0 bytes. Say the word and I'll write this to `docs/reviews/claude-architecture-art-review-2026-08-13.md` — a new dated file rather than backfilling the 08-12 one, since this review isn't identical to whatever `ARCHITECTURE-FINAL.md` synthesized and backdating it would make the record subtly false.

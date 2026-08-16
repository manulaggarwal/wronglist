# Post-Update Audit — Deutschland Journey + Hermes

Read on disk: `EVALS.md`, `CLAUDE.md`, `NEXT.md`, `ARCHITECTURE-FINAL.md`, `grammar-teaching-example.md`, 6 worker SOULs + x-articles SOUL + global SOUL + wlg SOUL, x-articles `SKILL.md`, WLG `README.md`/`anti-patterns.md`, Obsidian `AGENT.md`/`_index.md`, `Blast Radius` note. Verified repo↔vault sync by diff.

---

## 1. EVALS.md audit — ⚠️ needs work

**What's RIGHT:** §2 is the best thing produced in these 48 hours. 22 rows, each with *why it failed* **and** the correct version — that's the format that actually prevents recurrence. The taxonomy spans four genuinely different failure classes (invented words, wrong glosses, institutional/factual errors, and safety). `Kapo` and `Volksverhetzung` are catches that would otherwise have shipped, and shipping them would have been unrecoverable. Tagging §3 criteria with their originating review (R1/R2/R3) is rare provenance discipline.

**What needs fixing:**

1. **The Stammtisch golden example commits the file's own #1 failure.** "die neue **Radlane**" and "Ich finde die **Lane** eigentlich gut" — *Radlane* is not a German word. It's *der Radweg* / *Radfahrstreifen* / *Radspur*. §2 row 1 is literally "Ich bin fixesig | Invented word." A golden example containing an anglicized coinage teaches the generator that coinages are fine in casual register. **Fix:** `"Wir haben gerade über den neuen Radweg gesprochen."` / `"Ich finde den Radweg eigentlich gut."`
2. **"Bürgeramt München" is institutionally wrong.** *Bürgeramt* is the Berlin term; Munich runs citizen services through the **Kreisverwaltungsreferat (KVR)** / *Bürgerbüro*. Same class as the Praxisgebühr row — plausible-sounding, factually wrong. **Fix:** `Landeshauptstadt München — Kreisverwaltungsreferat`.
3. **"Ich bin erst letzte Woche angekommen"** — a new tenant *ist eingezogen*. *Angekommen* = arrived in the country. The annotation calls this "culturally exact."
4. **Annotations overclaim, and annotations are what a generator pattern-matches.** Bakery: "real register shift (Sie from baker, casual from customer)." There is no du/Sie marker in the customer's lines at all — "Ein Brot, bitte" is register-neutral. The only Sie marker is "Danke Ihnen" (and *Ich danke Ihnen* is the more idiomatic form).
5. **Provenance is the deepest problem.** The header says "Seed set from real German usage." The *Radlane* error proves at least part of it is model-generated. A golden example produced by the same class of system it exists to police is a hypothesis, not a bar. Mark all four `status: unverified` with a `verified_by` / `verified_date` field, blank until the editor signs.
6. **No metadata per example.** No region, no register tag, no situation ID. "Brezn" is Bavarian; nothing stops a generator from putting it in a Hamburg bakery. Add frontmatter: `region`, `level`, `register`, `situation`, `verified_by`.
7. **§2 claims "grep for failure patterns" but isn't greppable.** ~10 rows are literal strings; ~12 are conceptual ("Insurance at airport as entry requirement"). No script exists. Split into `evals/forbidden-strings.txt` (grep-able in CI today, inherited by `tools/validate.lua` at Day 22-23) + a human checklist for the conceptual half.
8. **§3 has two unresolved tensions and no test column.** "Density of named things" (max props) vs "One idea per screen" (Kanto is memorable *because* it's simple); "Fun without German" (floor) vs "German becomes the controller" (arc). Both are reconcilable but stated as absolutes with no precedence, so an agent resolves them arbitrarily. And every row is a principle with no observable check — that's taste, not an eval. Add "How to test": *Fun without German* → strip all German from the layer spec; is there still a decision with a consequence? No = fail.
9. **Missing:** golden examples for **glosses** (`Handschuh → glove (hand + shoe)` is locked, player-facing output with zero eval coverage); **near-miss negatives** (plausible-but-wrong German paired to each golden — highest-signal eval format); a **coverage map** (113 layers, zero situational tracking).

---

## 2. SOUL.md audit — ⚠️ needs work

**What's RIGHT:** Real improvement over identical 513B boilerplate. Each stance is defensible and non-overlapping — debugger (reproduce → binary search), refactorer (behavior-preserving, small steps), security-auditor (threat-model first). All sit under the 3,000-char lint threshold the wlg `knowledge-base-lint` enforces. x-articles is strong on identity: redundancy-first, builder-not-buyer, education-before-verdict, hype-skeptical — and preserving the voice rule verbatim was correct.

**What needs fixing:**

1. **Distinct in tone, not in behavior.** All 16 share one skeleton (identity para → "Voice & Approach" bullets → "You speak like someone who…"), and nearly every bullet is generic best practice a competent model already does: "read the error message," "test behavior not implementation," "secrets never in code." Honest test: swap architect's SOUL for "you are a helpful architect" — does output measurably change? Barely. `wlg/SOUL.md` changes behavior on *every* task (vault-first, verify-live-before-done, no tables on Telegram, theme ID lock). That's the bar.
2. **Zero grounding in your actual stack.** architect's "nobody got fired for choosing PostgreSQL" — there is no Postgres anywhere here; the stacks are Lua/LÖVE2D and Shopify Liquid + React islands. frontend-engineer says nothing about felt-ui, tokens-only, `pnpm police`, the 1.15rem floor, or the locked `#3D7A7B`. **One line of real constraint beats five aphorisms.**
3. **code-reviewer has a wrong severity order baked in:** *"Security, performance, correctness — in that order."* Correctness outranks performance essentially always. Fix to: *"Correctness and security first; performance third; style last and labeled as such."*
4. **The Telegram voice rule exists in exactly one of 19 profiles.** Global `~/.hermes/SOUL.md` doesn't have it; the 16 workers don't. Same user, same channel, hard contract from one profile and undefined behavior from the rest. It's a **channel-level** rule — move it to `~/.hermes/SOUL.md`, leave a pointer in x-articles.
5. **The global SOUL is still mostly the shipped template** — 7 generic lines plus the original commented-out example block. It's the one file every profile inherits and the least invested in. Highest leverage in the system.
6. **x-articles SOUL duplicates SKILL.md procedure — tripping the constitution check the same 48 hours created.** "prefer web_extract on direct URLs, fetch bookmarks with `-n 5`, never re-fetch on propagation delay" are all documented at length in SKILL.md (§Cost-efficient retrieval, §web_extract primary, §Pitfalls). wlg's lint Category 5 explicitly flags "SOUL/skill procedure duplication" — but at 2,428 chars this slips under the >3,000 gate silently. **Fix:** keep the judgment ("X API credits are finite; when a cheaper path exists, take it"), let SKILL.md own `-n 5`.
7. **The best x-articles lesson is in the wrong file.** The Felt UI incident — *"the agent does NOT know the full inventory; probe before declaring a gap; one question beats a wrong verdict"* — lives in SKILL.md step 3. That's an epistemic stance, not a procedure, and it's exactly what a redundancy-first identity is most likely to get wrong. **Swap it in for the `-n 5` clause.**
8. Minor: SKILL.md carries fossilized state ("$9.25 remaining at time of writing") — the SOUL lint's fossilization rule should extend to skills.

---

## 3. Structure audit (CLAUDE.md / AGENT.md / NEXT.md) — ⚠️ needs work

**What's RIGHT:** The three-way split is correct and the jobs are genuinely different — constitution + conventions (repo), vault navigation (vault), ordered work (both). No *architectural* contradictions: where the two locked-decision lists overlap they agree with ARCHITECTURE-FINAL, the off-limits lists agree, Current Phase agrees. Repo and vault EVALS copies are byte-identical (verified) — the sync discipline is real.

**What needs fixing:**

1. **EVALS.md is an orphan in every entry point.** Grepped: absent from CLAUDE.md's Key Documents table, absent from NEXT.md, absent from AGENT.md's nav table, absent from `_index.md`. An agent reading all three gets a coherent picture that *does not contain the eval file*. Cheapest high-value fix in this audit.
2. **Two different partial copies of the locked list.** CLAUDE.md enumerates 9 "key points"; AGENT.md enumerates 10 "Key Decisions (Locked)"; different subsets, both numbered 1..n as if authoritative, neither is the 18. Any edit to ARCHITECTURE-FINAL desyncs both silently. **Fix:** both say *"18 decisions live in ARCHITECTURE-FINAL — not re-enumerated here"*; keep only CLAUDE.md's Critical Rules (that section earns its place).
3. **NEXT.md's native-editor premise is now false.** It says the editor is "not needed until first dialogue exists" — dialogue now exists, four samples, in EVALS.md, presented as *the quality bar*. The highest-consequence unverified content in the project is parked in the 🟢 bucket.
4. **Day 0 has three different acceptance tests.** ARCHITECTURE-FINAL: draw one screen, show 5 people, no test. NEXT.md: "draw it from memory after 15 **seconds**." EVALS §4: "a stranger spends 15+ **minutes** in the block, then draws 3+ correctly-placed features." The third needs a walkable block and a second person — that's a Prototype-1 test mislabeled Day 0, and untestable solo this week. Keep NEXT.md's version as Day 0; move EVALS' under a "Prototype 1 — Der Block" heading.
5. **No canonicality rule between repo and vault.** Four documents exist in full duplicate. AGENT.md never mentions the git repo; CLAUDE.md mentions the vault once, via NEXT.md. Nothing says which wins on conflict. `wlg/SOUL.md` already solves this ("the vault is authoritative and overrides MEMORY.md") — port that sentence.
6. **Count drift:** `_index.md` says "112 gameplay layers" in Status and "113" in the table; says "Three Claude Opus reviews complete" while `reviews/` holds 5 files; AGENT.md says "Three + architecture review"; CLAUDE.md says 4.
7. **The 2026-08-14 session has no daily log.** `daily-logs/` holds only `2026-08-13`, and NEXT.md is stamped 08-13. The most productive day left no trace in the mechanism built to carry context between sessions.

---

## 4. WLG golden-examples — ⚠️ needs work

**What's RIGHT:** Correct instinct, correct shape. "When a customer replies warmly to an agent-drafted email, add it — proven good" is the best line in the file: it makes the set self-improving on real signal rather than opinion. `anti-patterns.md` mirrors the German EVALS column structure (pattern / why / fix) — cross-project consistency is worth keeping.

**What needs fixing:**

1. **No redaction rule, and the folder is inside a git repo.** "Copy 3-5 real customer emails" with no anonymization instruction and no gitignore. Real mail carries names, addresses, order numbers. **Add:** replace names with `[Customer]`, strip addresses/order refs/emails — or gitignore `emails/` outright.
2. **No coverage map, so the set will be all easy cases.** Left to instinct anyone seeds five warm, pleasant emails — but tone breaks on the hard ones. **Specify:** (a) order confirmation, (b) delay/late shipment, (c) damaged or wrong item, (d) bespoke request, (e) **saying no** (refund refusal), (f) wholesale enquiry, (g) review request. One each beats five of type (a).
3. **No entry template.** An email without its situation is just prose — the agent can't tell what it's an example *of*. Frontmatter per file: `situation`, `order_stage`, `what_made_it_good`, `outcome`; filename `NN-situation.md`.
4. **Criteria don't connect to the brand spec that already exists.** "Sign-off matches the warmth of the brand" never says what the sign-off *is*. WLG-v2's CLAUDE.md already locks a design language — name the actual sign-off and 2-3 banned phrases. That converts criteria into checks.
5. **anti-patterns.md is empty when it needn't be.** Generic e-commerce failures are knowable in advance: over-promising a ship date on made-to-order; stacking "unfortunately"; apologizing without a remedy; corporate voice ("we value your business"); repeating the first name more than once; burying the answer under pleasantries. Five seeded rows make it useful today instead of on day N.
6. **Same wiring failure** — `docs/golden-examples/` is referenced by nothing outside itself, including WLG-v2's CLAUDE.md.

---

## 5 & 6. Contradiction check — ⚠️ two real hits

1. **§2 logs two failures that are still live in the file it names.** `docs/grammar-teaching-example.md:24` still reads *"Items on counter with faint labels: **der Brezel**, das Brot, der Kuchen"* and `:47` still shows *"**die Croissant** ████ 30%"* — in **both** the repo and the vault, and `_index.md` links it as the worked grammar example. Review 1 flagged them; EVALS recorded them; nobody fixed them. **Recording a failure is not fixing it** — and a wrong article in the scaffold of a document about articles is the finding itself.
2. **The pixel art bar may exceed the locked pipeline.** §4 sets **Dead Cells** as the bar for "modern lighting on pixel art." Dead Cells achieves that via 3D-rendered sprites with normal-mapped dynamic lighting; ARCHITECTURE-FINAL §2.4 explicitly **skips normal maps and 2D shadow casting** in favor of light sprites + painted AO + contact shadows. Not a reopened decision — but an unreachable bar is a permanent fail state. Restate as "Dead Cells' *palette and contrast under lighting*, via light sprites," or swap the reference.
3. Day 0's three tests (§3.4 above).
4. Otherwise clean: "stratification not gating," "grammar as friction," "islands not blur," "typography is difficulty signal" all match the locked set. **No new file reopens a locked decision** — that discipline held.

---

## Top 3 next improvements, ranked

**1. Fix EVALS' own content, then wire it in.** Correct *Radlane* → *Radweg*, *Bürgeramt* → *Kreisverwaltungsreferat*, *angekommen* → *eingezogen*; mark all four examples `unverified`; add region/register/situation metadata; fix the two live errors in `grammar-teaching-example.md` in both stores; add EVALS.md to CLAUDE.md's Key Documents, AGENT.md's nav, and NEXT.md's 🔴 block. *Right now the eval file teaches an error it exists to prevent, and no agent will ever open it.* ~30 minutes.

**2. Move the native editor to 🔴 and make §2 executable.** Your own *Blast Radius* note is the argument: "a root-node error poisons everything downstream — downstream agents reinforce the mistake because bad output is simply their input." The golden examples are the root node for every line of German the project will ever generate, and they are currently unverified model output with one confirmed invented word. Split the ~10 literal-string failures into `evals/forbidden-strings.txt` with a CI grep this week (10 lines of shell; `tools/validate.lua` inherits it at Day 22-23), and start the editor search now rather than "when dialogue exists."

**3. Rewrite SOULs for behavior, not voice — starting with the global.** Move the Telegram voice contract into `~/.hermes/SOUL.md` so all 19 profiles inherit it. Add 1-2 lines of real stack constraint per worker SOUL (frontend-engineer: tokens-only, 1.15rem floor, no glassmorphism, no hand-rolled dashes; architect: Lua/LÖVE2D + Liquid islands, not Postgres). Fix code-reviewer's severity order. In x-articles, swap the `-n 5` procedure out for the probe-before-declaring-a-gap rule. *Sixteen distinct voices attached to sixteen identical generic behaviors is a smaller win than it looks; grounding two or three of them in your real constraints is a bigger one.*

# Roadmap

The feature list: what is built, what is next, and what is waiting on a decision. **This is the starting point for choosing work.** `CLAUDE.md` says how to build; `docs/design/` says what the game is; this file says where it stands.

## How to use it

- **Status:** `[x]` built · `[~]` in progress · `[ ]` not started · `[?]` waiting on a design decision from the user · `[-]` cut (say why in Notes).
- **Picking work:** continue any `[~]` first. Otherwise take the first `[ ]` whose `Needs` are all `[x]`, in the order the user set, or ask. Never start a `[?]` item: ask the question in its Notes.
- **IDs are permanent.** New items get the next free number in their area; a cut item keeps its row as `[-]`. Commit bodies and knowledge entries cite the ID (`Roadmap: SONG-09`).
- **When an item changes status,** update its row and the `Updated` date in the same commit as the code. When an item is built, link its `docs/knowledge/systems/` or `features/` entry in Notes.
- **Design is the source of the scope.** An item that is not in `docs/design/` needs the user's go-ahead before it is added. Items here cite the section they come from.

## Core play

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| CORE-01 | Movement: run, jump, landing, wall land | 02 Controles | `[x]` | | 2026-10-02 | |
| CORE-02 | Sword combat and combos | 02 §2 | `[x]` | | 2026-10-02 | |
| CORE-03 | Common enemies (brute shadow) | 02 §2 | `[x]` | | 2026-10-02 | Enemies take hazard damage but never respawn; nothing keeps them out of water. |
| CORE-04 | Teaching creatures (criaturas-professoras) | 02 §2 | `[?]` | | 2026-10-02 | Design names them; behaviour undefined. |
| CORE-05 | Gamepad layout and device glyphs | 02 Controles | `[x]` | | 2026-10-02 | `systems/input` |
| CORE-06 | Climbing (on roots) | 02 §7.1 | `[x]` | SONG-07 | 2026-10-02 | Template ladder and ledge clips unused. |

## Memory and world

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| MEM-01 | Memory field and the greyhush | 03 §2-3 | `[x]` | | 2026-10-02 | `systems/greyhush` |
| MEM-02 | Seasonal art and the season mask | 03 §5.2 | `[x]` | | 2026-10-02 | `systems/seasonal-art` |
| MEM-03 | Region memory, wells and restoration | 03 §4 | `[x]` | | 2026-10-02 | |
| MEM-04 | Regional weather (visual) | 03 §5 | `[x]` | | 2026-10-02 | Only art is each palette's pulse particles. |
| MEM-05 | Regional weather pushes the player | 03 §5 | `[ ]` | MEM-04, MEM-07 | 2026-10-02 | Weather numbers pending prototyping (03 §7). |
| MEM-06 | Profiles for summer storm, autumn leaves, spring drizzle | 03 §7 | `[?]` | | 2026-10-02 | Only winter is described. |
| MEM-07 | Air channel and wind zones | 03 §5.3-5.4 | `[x]` | | 2026-10-02 | `systems/air` |
| MEM-08 | Water: pools, lakes, reflection, ice, hazard, rain basins | 03 §6 | `[x]` | | 2026-10-02 | `systems/water`. Ripples are lost when a room is evicted. |
| MEM-09 | Water current | 03 §6 | `[ ]` | MEM-08 | 2026-10-02 | Hook: `WaterVolume.disturbances()`. |
| MEM-10 | Waterfalls | 03 §7 | `[?]` | | 2026-10-02 | Needs its own design pass (freeze the whole fall or the base?). Inverno Espacial 1 depends on it. |
| MEM-11 | Death marks | 03 §4.3 | `[x]` | LIFE-02 | 2026-10-02 | |
| MEM-12 | Foreground art layer | | `[ ]` | | 2026-10-02 | Needs its own creature-bit treatment; characters draw over the finished world. |
| MEM-13 | Starting memory per region | 03 §7 | `[?]` | WORLD-03 | 2026-10-02 | Village decided: 0.8 at the start, 1.0 at the Return. |
| WORLD-04 | Background layers of regions placed away from the origin | | `[ ]` | | 2026-10-07 | `Parallax2D` ignores its parent's offset, so the far layers are off screen in the trials: `gotchas/parallax2d-ignores-its-parents-offset`. |

## Songs

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| SONG-01 | Songs as data, the Memorina, performance and lesson | 02 §6.2, §7 | `[x]` | | 2026-10-02 | `systems/songs-and-the-memorina` |
| SONG-02 | Congelar (FREEZE) | 02 §7.1 | `[x]` | | 2026-10-02 | |
| SONG-03 | Redoma (BELL_JAR) | 02 §7.1 | `[x]` | | 2026-10-02 | `systems/bell-jar` |
| SONG-04 | Sombra (SHADOW) | 02 §7.1 | `[x]` | | 2026-10-02 | Burned shadow copies the playing pose; no ash art beyond particles. |
| SONG-05 | Solstício (SOLSTICE) | 02 §7.1 | `[x]` | | 2026-10-02 | `systems/solstice` |
| SONG-06 | Soltar (RELEASE) | 02 §7.1 | `[x]` | | 2026-10-02 | |
| SONG-07 | Enraizar (ROOT) | 02 §7.1 | `[x]` | | 2026-10-02 | `systems/roots-and-climbing` |
| SONG-08 | Vendaval (GALE) and Chuva (RAIN) | 02 §7.1 | `[x]` | | 2026-10-02 | |
| SONG-09 | A reduced excerpt per song | 02 §7 | `[ ]` | | 2026-10-02 | `Song.excerpt` is null everywhere; the track is cut at 7 s. |
| SONG-10 | Tune `note_cues` against each track | | `[ ]` | | 2026-10-02 | Placeholders 0.5 s apart. |
| SONG-11 | Effect durations calibrated | 02 §9 | `[ ]` | | 2026-10-02 | `IceProfile` and other timings are first guesses. |
| SONG-12 | Root bridge strands meet level | | `[ ]` | | 2026-10-07 | The two strands meet 4 px apart in height: `bugs/root-bridge-strands-meet-at-a-step`. |

## Puzzles

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| PZL-01 | Song trials (one room per season, plus the Solstice corridor) | 02 §8 | `[x]` | | 2026-10-02 | Debug builds only, F10. |
| PZL-02 | Combinado 1: Chuva then Congelar, ice outlives the drain | 02 §8.4 | `[ ]` | | 2026-10-02 | A frozen basin holds its level today. |
| PZL-03 | Combinado 2: Vendaval then Congelar, frozen crest ramp | 02 §8.4 | `[ ]` | | 2026-10-02 | Wind already moves water. |
| PZL-04 | Combinado 3: Soltar then Enraizar, catch in mid-fall | 02 §8.4 | `[ ]` | | 2026-10-02 | |
| PZL-05 | Combinado 4: Solstício, Sombra and Soltar, the empty house | 02 §8.4 | `[x]` | | 2026-10-07 | `empty_house` in the Solstice trials; a gate's `second_trigger_path`; Solstice's stretch is 3.0x (user, 2026-10-07). `systems/solstice`, `systems/weight-presence-release` |
| PZL-06 | Redoma then Congelar: curved ice wall (Inverno Lógico 2) | 02 §7.4 | `[ ]` | | 2026-10-02 | |
| PZL-07 | Windy-spot puzzle for Redoma (Inverno Lógico 1) | 02 §8 | `[ ]` | | 2026-10-02 | Shelter is unit-tested only. |
| PZL-08 | Chuva then Enraizar in a trial (wet earth) | 02 §7.4 | `[x]` | | 2026-10-07 | Spring trial puzzle 5. A joined wet bridge holds while Enraizar does (user, 2026-10-07). `systems/roots-and-climbing` |
| PZL-09 | Rising pool above a painted rest level | 03 §6.5 | `[ ]` | | 2026-10-02 | Chuva fills dry basins only. |

## Guardians

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| GRD-01 | Guardian framework: phases, call, recall, AI, staging | 02 §3-4 | `[x]` | | 2026-10-02 | `systems/guardians` |
| GRD-02 | Bloom Guardian (ROOT + DOUBLE_JUMP) | 02 §7.2 | `[x]` | | 2026-10-02 | |
| GRD-03 | Frost Guardian (FREEZE + ROLL) | 02 §7.2 | `[x]` | | 2026-10-02 | Free sprite tier: one attack clip for all moves. Later cycles never playtested. |
| GRD-04 | Summer and autumn guardians | 02 §7.2 | `[?]` | WORLD-03 | 2026-10-02 | Which skill each recalls is undecided (02 §4). |
| GRD-05 | Arena doors (no walking out mid-fight) | | `[ ]` | | 2026-10-02 | |
| GRD-06 | Final battle: revelation and dissonance | 02 §5 | `[ ]` | GRD-04 | 2026-10-02 | |

## Life and saving

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| LIFE-01 | Life HUD (notes that lose their colour) | 02 Vida | `[x]` | | 2026-10-02 | `systems/life-benches-death` |
| LIFE-02 | Benches, the save ledger and death rewind | 02 Vida | `[x]` | | 2026-10-02 | Three benches exist. |
| LIFE-03 | Sit and stand transitions, a real sit pose | 02 Vida | `[ ]` | | 2026-10-02 | Uses the pack's crouch-idle at 2x. |

## Interface

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| UI-01 | Memorina sheet and guardian call HUD | 02 UI | `[x]` | | 2026-10-02 | |
| UI-02 | Pause menu | 02 Controles | `[x]` | | 2026-10-02 | `systems/screens`. Quit to title comes with UI-05, Settings with UI-07. |
| UI-03 | Field notebook (lore, songs, items, guardians) | 02 UI | `[x]` | | 2026-10-06 | `systems/notebook`. Confirms a recalled skill with a diary entry (02 §4). Mentor entries come with STORY-03. |
| UI-04 | Map (drawn by exploration) | 02 UI | `[x]` | | 2026-10-06 | `systems/map`. |
| UI-05 | Title screen and load menu | 02 UI | `[x]` | | 2026-10-06 | `systems/screens`, `systems/life-benches-death`. Three slots; main menu gets Settings with UI-07. |
| UI-06 | Victory screen | 02 UI | `[?]` | GRD-06 | 2026-10-02 | |
| UI-07 | Settings: volume, language, display, rebinding | | `[ ]` | UI-02 | 2026-10-02 | The user's go-ahead, 2026-10-02. Pause and title show Settings once it exists. |

## Story

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| STORY-01 | Lesson cinematic | 02 §7.2 | `[x]` | | 2026-10-02 | |
| STORY-02 | Pickups: the world grants the sword and the Memorina | 01 §5 | `[ ]` | | 2026-10-02 | Debug builds start owning both. |
| STORY-03 | Mentor and the opening | 01 §4, §8 | `[?]` | | 2026-10-06 | Mentor's name is open (01 §10). Notebook: two mentor entries, a short one after the Memorina is given and a real one at his restoration (the user, 2026-10-02); the Frost Guardian is not the mentor. |
| STORY-04 | Bearer fragments, one per tube | 01 §6 | `[ ]` | UI-03 | 2026-10-02 | |
| STORY-05 | Five playable flashbacks | 01 §9.3 | `[ ]` | | 2026-10-02 | |
| STORY-06 | Letters, diaries and other collectibles | 01 §6 | `[ ]` | UI-03 | 2026-10-02 | |
| STORY-07 | Epilogue | 01 §9.4 | `[ ]` | GRD-06 | 2026-10-02 | |

## World

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| WORLD-01 | Home village: downtown, woods, Bloom Hollow | 01 §8 | `[x]` | | 2026-10-02 | |
| WORLD-02 | Frost edge: the lighthouse | | `[x]` | | 2026-10-02 | |
| WORLD-03 | The world map: regions and their order | 01 §10 | `[?]` | | 2026-10-02 | Map is open in design. |

## Tools and infrastructure

| ID | Item | Design | Status | Needs | Updated | Notes |
|---|---|---|:-:|---|---|---|
| TECH-01 | Playtest capture harness | | `[x]` | | 2026-10-02 | |
| TECH-02 | Rooms as text maps | | `[x]` | | 2026-10-02 | `systems/rooms` |
| TECH-03 | Art pipeline (contracts, Codex, PixelLab, processing) | | `[x]` | | 2026-10-02 | `systems/art-pipeline` |
| TECH-04 | Export presets and a release build | | `[ ]` | | 2026-10-02 | No `export_presets.cfg` yet. |

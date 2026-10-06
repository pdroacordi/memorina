# Memorina

Godot 4.7 (GDScript, Forward+), a 2D metroidvania. Four documents answer different questions:

| Question | Where |
|---|---|
| What is the game? (lore, mechanics, world; Portuguese) | [`docs/design/`](docs/design/) `01_lore_e_narrativa.md`, `02_mecanicas.md`, `03_mundo_e_ambiente.md` |
| What is built, what is next? | [`docs/roadmap.md`](docs/roadmap.md) |
| How does system X work, and what must not break? | [`docs/knowledge/systems/`](docs/knowledge/systems/) (table below) |
| Why was it built this way; what broke before? | [`docs/knowledge/`](docs/knowledge/README.md) `architecture/`, `bugs/`, `gotchas/`, `playtests/` |

This file holds only the rules that apply everywhere. **Before changing a system, read its systems entry.** Those entries are the contract; this file no longer repeats them.

## Architecture principles

Object-oriented, SOLID and KISS. In Godot terms:

- **Composition over inheritance.** Small single-purpose scripts wired together. Inheritance only for real "is-a" on engine base classes.
- **One responsibility per script.** `PlayerInput` owns all `Input`/`InputEvent` knowledge and action names; `Player` owns state and behaviour. Every controller (guardians, enemies, UI) follows this split; no logic node reads `Input`.
- **Continuous input is a property, discrete input is a signal.** Axes and held modifiers are typed read-only properties sampled on read (caching them in `_physics_process` adds a frame of lag, because parents process before children). Presses are signals. A "changed" signal carrying a level value every frame is the anti-pattern.
- **Signals for decoupling**, not `get_node()` chains.
- **Resources for data-driven variation** (attack patterns, note sequences), not branches in one script.
- **Shallow scene trees.** Depth for behaviour means a script or sub-scene is missing.
- **Thin autoloads**, for genuinely global state only.
- **`Character extends CharacterBody2D`** (`scenes/characters/character.gd`) owns only what every character has: facing, gravity, health/hurtbox wiring, knockback, and `_physics_process` as a template method (`_process_motion` → `move_and_slide()` → `_after_move`). Subclasses override the two hooks, never `_physics_process`.
- **`CharacterController extends Node`** supplies intent (`PlayerInput`, enemy AI). Its `direction` uses `get = _get_direction` so subclasses can override it.
- **Generic behaviour** goes in `scenes/characters/components/`. Anything gated by `Enums.PlayerSkill` is a player ability in `scenes/characters/ivo/abilities/`. The gate reaches a component as a plain `enabled` flag set when the ability is attempted; components never read `SaveSystem`.
- **When a component takes over a signal `Player` used to emit, `Player` re-emits it**, because `ivo.tscn` connects with `from="."`.

## GDScript conventions

- Static typing everywhere: `:` on variables and parameters, `->` on returns, `:=` for inference.
- snake_case files, functions, variables and signals (signals past tense: `door_opened`); PascalCase `class_name`; CONSTANT_CASE constants; `_` prefix for private members.
- Identifiers are English even for Portuguese design terms (Congelar → `FREEZE`). The mapping is [`docs/knowledge/glossary.md`](docs/knowledge/glossary.md); check its retired-terms table before naming anything.
- Class body order (GDScript style guide): annotations, `class_name`, `extends`, docstring, signals/enums/consts, exports, vars, `@onready` vars, `_init`/static, virtuals, public, private, inner classes.
- Tabs, double quotes, trailing commas in multi-line literals.

## Comments

Code says what. A comment says only what the code cannot.

Write a comment only when it carries one of these:
- **Why** a non-obvious choice was made, in one sentence. `# Deferred: a body cannot change state inside the physics flush.`
- **A constraint** a later edit could break. `# Must match gh_influence() in greyhush_common.gdshaderinc.`
- **Units or range** the name does not carry: `px/s`, `0..1`, `real seconds`.
- **A pointer** to a design-doc section, a `docs/knowledge/` entry or a bug file.

Do not write:
- A restatement of the name, type or signature (`## The player's health.` over `var health`).
- The story of the system, its history, or what was tried before. That goes in `docs/knowledge/`, linked in one line.
- Metaphor, emphasis in CAPITALS, or quoted design-doc prose. Cite the section instead.
- Commented-out code.

Form:
- `##` doc comments are one sentence, two at most. Anything longer is an architecture note: move it to `docs/knowledge/` and link it.
- Plain, literal technical English: subject, verb, fact.
- An exported tunable gets its unit and what it controls, on one line.
- Fewer, shorter comments stay true longer. A comment is wrong the moment the code under it changes.

Before (`player.gd`):
```gdscript
## The death clip has played out. The composition root waits on this before
## the screen goes dark, so the fall is seen, not cut.
signal death_shown
```
After:
```gdscript
## The death clip finished. Game waits for it before fading out.
signal death_shown
```

The same rules apply to documentation: state the fact, the number and the reason, without narrative.

## Systems

Read the entry before touching the system. The rule beside each is the one most often broken; the entry has the rest.

| System | Entry | Never break |
|---|---|---|
| Animation | [`systems/animation`](docs/knowledge/systems/animation.md) | The resolver owns every clip name as a `const`; no transitions or `advance_expression` in a tree. A property with a `RESET` track is overwritten every frame: gate the decision in script, or key it. |
| Greyhush (memory field) | [`systems/greyhush`](docs/knowledge/systems/greyhush.md) | Grey is stopped time, not a colour filter. `MemoryFieldMath` and `greyhush_common.gdshaderinc` are one formula in two languages: change both. Dither in game pixels (`UV * game_size`), never `FRAGCOORD`; animate from `greyhush_time`, never `TIME`. Characters never freeze. |
| Songs and the Memorina | [`systems/songs-and-the-memorina`](docs/knowledge/systems/songs-and-the-memorina.md) | A song is data. Gameplay reads the clean disc, never the dithered edge. The pause-mode map there is exact: add to it, never set a whole `CanvasLayer` to ALWAYS. |
| Guardians | [`systems/guardians`](docs/knowledge/systems/guardians.md) | A concrete guardian is a scene plus `GuardianStats`, not a subclass. `GuardianFight` is pure and owns the clock; HUDs only draw it. `WorldFreeze` is the only writer of `Engine.time_scale` and `get_tree().paused`. |
| Seasonal art | [`systems/seasonal-art`](docs/knowledge/systems/seasonal-art.md) | Scenes reference band 0; the material declares which band is which season. No high-frequency texture in the grey. |
| Air | [`systems/air`](docs/knowledge/systems/air.md) | Wind is a velocity the air carries, never a force. |
| Weight, presence, release | [`systems/weight-presence-release`](docs/knowledge/systems/weight-presence-release.md) | Release signals are emitted deferred (physics flush). |
| Roots and climbing | [`systems/roots-and-climbing`](docs/knowledge/systems/roots-and-climbing.md) | Roots join earth to earth; stone never roots. |
| Bell jar (Redoma) | [`systems/bell-jar`](docs/knowledge/systems/bell-jar.md) | `wc_held()` and `WaterBody._refresh_dry()` are the same test: change both. |
| Solstice | [`systems/solstice`](docs/knowledge/systems/solstice.md) | Stretch takes once, only while a pulse opens or holds. |
| Water | [`systems/water`](docs/knowledge/systems/water.md) | Reflect below z 50, cover water above it. Never `TIME` or `FRAGCOORD` in water shaders. Hazards detect the body, never the hurtbox. |
| Life, benches, death | [`systems/life-benches-death`](docs/knowledge/systems/life-benches-death.md) | Only benches save. Death rebuilds the world by swapping `game.tscn`, never `reload_current_scene()`. Headless runs and the playtest runner never touch a player's save (`BootPolicy`). Move a character with `Character.teleport`, never a position write. |
| Input | [`systems/input`](docs/knowledge/systems/input.md) | Only `PlayerInput`, `MenuInput` and `InputDevice` read `InputEvent`s. |
| Screens (menus) | [`systems/screens`](docs/knowledge/systems/screens.md) | Screens only asks `WorldFreeze` to hold and releases only what it held. The Screens root Control is ALWAYS, never its CanvasLayer. Every tween under Screens ignores the time scale. |
| Rooms | [`systems/rooms`](docs/knowledge/systems/rooms.md) | Rooms are `.room` text; never paint ground in the editor. Bump the importer's `FORMAT_VERSION` when the parser changes. |
| Art pipeline | [`systems/art-pipeline`](docs/knowledge/systems/art-pipeline.md) | Art starts as a contract in `tools/art/prompts/`. Never upload pack art as a reference (licences forbid AI training). Credit everything in `CREDITS.md`. |

A new system gets a new entry here and in `docs/knowledge/systems/` in the same change.

## Working on the roadmap

- Pick work from [`docs/roadmap.md`](docs/roadmap.md); its header says how. Multi-item runs use the `feature-loop` skill.
- Every code change passes the `verify-gates` skill before it is committed or marked done. Gameplay-visible changes are also playtested (`godot-playtest`).
- A user decision is recorded in their words, with the date, in the systems entry it changes.

## Testing

`$GODOT` (console) and `$GODOT_WINDOWED` are set in `.claude/settings.json`.

```bash
"$GODOT" --headless --path . --import                       # after a new class_name or an edited .room
"$GODOT" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests
"$GODOT" --headless --path . res://tools/smoke/smoke.tscn   # opens every scene in tools/smoke/scenes.txt; exit 1 on any error
```

- Pure logic lives in a `RefCounted` with a suite under `tests/`, mirroring the source path. `--ignoreHeadlessMode` is required; no suite uses input.
- Add every new playable scene to `tools/smoke/scenes.txt`.
- **Song trials** (`scenes/world/rooms/trials_<season>.tscn`) are where song puzzles are built and tested. `DebugTrials` mounts them in debug builds only; F10 moves Ivo to the next. Playtest positions: winter x 0, summer 2400, autumn 4800, spring 7200, Solstice 9600; floor y 6000.

## Playtesting

Tests verify correctness, not feel. After a gameplay-visible change, run the `godot-playtester` agent (or the `godot-playtest` skill). `tools/playtest/` runs the real game windowed and drives a JSON input timeline (`tools/playtest/scripts/*.json`) through `Input.parse_input_event()` (`action_press` does not reach input callbacks). A timeline can set `"player_position": [x, y]` and `"known_songs": [ids]`. Reports go to `docs/knowledge/playtests/` and state what screenshots cannot show (camera feel, latency).

## Knowledge base

[`docs/knowledge/`](docs/knowledge/README.md) is the project's engineering memory, in English. **Read the relevant entries before acting; write a new entry after learning something not already there.** Skipping the write because the task felt small makes the next session pay the same cost. `godot-architect` maintains `architecture/`, `godot-reviewer` maintains `bugs/` and `gotchas/`, `godot-playtester` writes `playtests/`, and whoever changes a system updates its `systems/` entry.

## Internationalization

The game ships in several languages. Never hardcode user-facing text in scripts or scenes; use `tr()` with a key from `i18n/translations.csv`. Portuguese design prose is content to translate, not a default.

## Project structure

**Every file and folder is lowercase `snake_case`** (`res://` is case-sensitive on Linux and web exports). Knowledge-base entries are the one exception (kebab-case slugs). Scripts live beside their scene, grouped by feature; there is no `scripts/` folder.

- `globals/`: autoloads and global enums (no owning scene).
- `scenes/characters/`: the shared substrate (`character.gd`, `character_controller.gd`, `character_state_machine.gd`); `components/` for reusable components; `<name>/` per character, with `abilities/` for its gated abilities.
- `scenes/combat/<kind>/`: hurtbox, hitbox, health, hazard.
- `scenes/world/`: `game.tscn` is the composition root (player, camera, HUD; swaps levels). `memory/` is the greyhush, `memory/seasonal/` the season mask. `environment/<kind>/` is ambient dressing that answers memory; `interactables/<kind>/` are things a song acts on (each composes a `SongReceiver`).
- `scenes/particles/<kind>/`: fire-and-forget effects. `scenes/ui/<screen>/`: HUD and menus.
- `resources/`: custom `Resource` scripts and their `.tres` (songs in `resources/songs/`, pulses in `resources/memory/`). `player_data.gd` lives in `globals/` as the save schema.
- `assets/sprites/<category>/<name>/` mirrors `scenes/`. `i18n/` holds translations. `tests/` mirrors source paths. `addons/` is vendored (gdUnit4, room_maps).
- `tools/`: scripts run by hand (asset pipeline, map docs) and `tools/playtest/`, a dev-only scene never referenced by the game.

Rooms are three levels; the `_contents` suffix tells the two `<room>.tscn` apart:

```
scenes/world/rooms/<region>.tscn                            composition: places the rooms
scenes/world/rooms/<region>/<room>.tscn                     the Room trigger (Area2D, room.gd), exports contents_scene
scenes/world/rooms/<region>/contents/<room>_contents.tscn   backgrounds + a RoomMap node, loaded lazily
scenes/world/rooms/<region>/contents/<room>.room            ground, water and entities as text
```

Rename and move files from the Godot editor's FileSystem dock, so it rewrites `uid://` references, `path=` entries and `.import` sidecars.

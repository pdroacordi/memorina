# Memorina

Godot 4.7 (GDScript, Forward+ renderer), 2D metroidvania. Design source of truth lives in [`docs/design/`](docs/design/) — `01_lore_e_narrativa.md` (lore/narrative) and `02_mecanicas.md` (mechanics). Both are in Portuguese (working design language); read them for gameplay/story context before implementing a system that touches lore or mechanics.

## Architecture principles

Bias hard toward object-oriented design and SOLID/KISS. Concretely, in Godot terms:

- **Composition over inheritance.** Prefer small, single-purpose scripts wired together over deep `extends` chains. Reserve inheritance for genuinely "is-a" relationships on engine base classes; use it sparingly even then.
- **Single responsibility per script/node.** A script should do one thing. If a node's script is handling input, physics, *and* state bookkeeping, split it — see `PlayerInput` / `Player` in `scenes/characters/player/` as the reference pattern: the input node owns all knowledge of `Input`/`InputEvent` and action names, and the logic node owns state and behavior. Extend this same split for every future controller (guardians, enemies, UI controllers) rather than reading `Input` directly inside a logic node.
- **Continuous input is a property; discrete input is a signal.** On an input node, continuous state (movement axes, held modifiers, directional ocarina input) is exposed as a typed read-only property that the logic node polls — sampled on read, never cached in `_physics_process`, which would reintroduce a one-frame lag since Godot processes parents before children. Discrete events (jump pressed/released, dash, attack, pause) are signals. A past-tense "changed" signal carrying a *level* value is the anti-pattern: it fires every frame, forces every consumer to keep a shadow copy of the value, and makes downstream logic accidentally depend on the emission cadence.
- **Signals for decoupling (Observer).** Nodes that need to react to something emit or listen to signals rather than reaching into each other via `get_node()` chains or tight parent/child coupling.
- **Resources for interchangeable data/behavior (Strategy).** Data-driven variation (e.g. per-guardian attack patterns, per-season note-sequence definitions) belongs in custom `Resource` subclasses, not in branching logic inside a single script.
- **Shallow scene trees.** If a scene's node hierarchy is growing deep to express behavior rather than actual spatial/rendering structure, that's a sign to extract a script or sub-scene instead.
- **No god-classes, no god-autoloads.** Autoload singletons are for genuinely global state (e.g. game progress) — keep them thin, delegate logic elsewhere.
- **The character substrate.** `Character extends CharacterBody2D` (`scenes/characters/character.gd`) is the shared base. It owns only what every character has: facing, gravity, health/hurtbox wiring, knockback, and `_physics_process` as a template method (`_process_motion` -> `move_and_slide()` -> `_after_move`). Subclasses override those two hooks rather than `_physics_process`.
- `CharacterController extends Node` (`scenes/characters/character_controller.gd`) supplies movement intent. `PlayerInput` is one; enemy AI will be another. A `Character` never learns where its intent comes from. Its `direction` property uses the `get = _get_direction` form rather than an inline getter, because an inline getter cannot be overridden by a subclass.
- Behaviour split rule: generic behaviour goes in `scenes/characters/components/`; anything gated by `Enums.PlayerSkill` is a player ABILITY and goes in `scenes/characters/ivo/abilities/` instead, so enemies never inherit abilities they cannot use.
- The skill gate is pushed onto ability components via a plain `enabled` flag at the moment the ability is attempted. Components never reference `SaveSystem`.

## GDScript conventions

- **Static typing everywhere for new code.** Use `:` for variable/param types, `->` for return types, `:=` for inferred assignment. This is a static-typing-first codebase.
- **Naming:** snake_case for files, functions, variables; PascalCase for classes (`class_name`); CONSTANT_CASE for constants; signals in snake_case past tense (e.g. `door_opened`); private members/methods prefixed with `_`.
- **Code identifiers are English**, even where they name a design concept described in Portuguese in `docs/design/` (e.g. the "Congelar" sequence → `freeze_sequence`, not `congelar`). Keep a mental (or eventually written) glossary mapping design-doc terms to their code names as they get implemented.
- **Class body order** (official GDScript style guide): annotations → `class_name` → `extends` → docstring → signals/enums/consts → exported vars → other vars → `@onready` vars → `_init()`/static methods → virtual methods (`_ready`, `_process`, etc.) → public methods → private methods → inner classes.
- Tabs for indentation, double quotes for strings, trailing commas in multi-line literals — standard Godot style guide.

## Animation

**Code decides, the AnimationTree renders.** Each character's `AnimationTree` is a flat set of clips with NO transitions and NO `advance_expression` strings. Two components sit beside it: `AnimationDriver` (generic playback — starts a clip only when the name changes) and an `AnimationResolver` (one concrete subclass per character: `PlayerAnimationResolver`, `BruteShadowAnimationResolver`). Every frame `Character._physics_process` calls `resolve()` on the resolver and hands the result to the driver. `resolve()` is an ordered priority chain; its order is the only tie-break anywhere.

- **The resolver owns the character's entire clip vocabulary** as `const` StringNames at its top, and nothing else names a clip — not the character script, not `Character`. The resolver reads the character's public predicates (`is_rolling()`, `just_hit()`, ...) and the driver; gameplay that needs to know an animation finished asks the resolver in gameplay terms (`is_death_finished()`, `is_spawn_finished()`). Adding an animation is: author the clip, add its node to the tree, add a const and one line at the right priority in the resolver. Never write a clip name as a loose `&"..."` literal — a typo in a const name fails to compile, a typo in a literal silently plays nothing. Never add a transition to a state machine.

- **Intro / one-shot clips** (`jump_start`, `fall_start`, `wall_landing`, `land`, `air_spin`, `hurt`, `spawn`) are held until they finish via `AnimationDriver.holding()` / `sequence()`; the resolver never needs their durations. An event that must restart the *same* clip (a pogo chain, a second hit mid-flinch) calls `AnimationDriver.request_replay()`. Events that arrive from the physics flush (hits, area triggers) land *after* the frame's `_physics_process`, so a pulse for them (`Character.just_hit()`) is cleared after the resolve, not before.
- **`RESET` is the default pose, and the tree owns every property it declares.** Each clip keys only what it changes (hitbox geometry per swing, i-frames); everything else blends back to `RESET`. Consequence: a script write to any property with a `RESET` track (`Hurtbox:monitorable`, `Hitbox:*`) is silently overwritten every frame. Gate the *decision* in script instead (`Character._on_hit_received` ignores hits while dead), or key it in the clip. `BruteShadow` keeps its tree inactive until spawn for exactly this reason.
- **Durations that must equal a clip's length are asserted at startup** in debug builds (`Character._assert_clip_length`): `roll_time + roll_recovery_time` vs the roll clip, every `AttackPhaseData.duration` vs its swing, `BruteShadowAttackStats.attack_duration` vs `attack`. Retune either side and the assert says which pair drifted.
- When a component takes over logic that previously emitted a signal from `Player`, `Player` must RE-EMIT that signal, because `ivo.tscn`'s connections are declared with `from="."`. This is why `Player` relays `jumped`, `double_jumped` and `hard_landed`.

## Internationalization

**This game ships in multiple languages — build for that from the start, don't retrofit it.**

- Never hardcode user-facing strings (dialogue, UI labels, notebook text) directly in scripts or scenes. Route everything through Godot's translation system (`tr()` with a key, backed by CSV or gettext `.po` files).
- Portuguese design-doc prose is source *content* to translate, not a hardcoded default — treat every user-facing string as a translation key from the first line of code that uses it.

## Project structure

**Every file and folder is lowercase `snake_case`** — no spaces, no PascalCase, no kebab-case. `res://` paths are case-sensitive on Linux/web exports, so mixed casing produces builds that work on Windows and break everywhere else.

- `globals/` — autoload singletons and global enums (`save_system.gd`, `enums.gd`, `player_data.gd`). These are scripts with no owning scene, which is why they are exempt from the "scripts live beside their scene" rule below.
- `scenes/characters/` (the root itself) — the generic character substrate shared by every character: `character.gd`, `character_controller.gd`, `character_state_machine.gd`.
- `scenes/characters/components/` — reusable behaviour components any character can mount (locomotion, jump, landing).
- `scenes/characters/<name>/` — one folder per character, containing its scene(s) *and* its scripts (e.g. `scenes/characters/ivo/`).
- `scenes/characters/<name>/abilities/` — components specific to ONE character, e.g. gated player abilities.
- `scenes/combat/<kind>/` — hurtbox, hitbox, health.
- `scenes/world/` — `game.tscn`, the main scene: the composition root holding player, camera and HUD, and swapping levels underneath.
- `scenes/particles/<kind>/` — reusable one-shot effect scenes, spawned by whoever triggers them.
- `assets/sprites/<category>/<name>/` — art, mirroring the `scenes/` layout (e.g. `assets/sprites/characters/ivo/`).
- `resources/` — custom `Resource` SCRIPTS defining tuning data plus the `.tres` instances of them, e.g. `resources/characters/`. Both the class definitions and their data live here; the exception is `player_data.gd`, which is the save-file schema owned by the `SaveSystem` autoload and so lives in `globals/` instead.
- `docs/design/` — design docs (lore, mechanics), source of truth for game intent.

**Scripts live beside the scene they belong to — never in a shared `scripts/` folder.** Grouping is by feature, not by file type. A `scripts/` directory would make every new file a coin flip between two conventions.

**Rooms are a three-level pattern** — easy to get wrong, so spelled out explicitly:

```
scenes/world/rooms/<region>.tscn                            composition: places the rooms
scenes/world/rooms/<region>/<room>.tscn                     the Room trigger (Area2D, room.gd), with contents_scene exported
scenes/world/rooms/<region>/contents/<room>_contents.tscn   the actual tilemap/background, loaded lazily
```

The `_contents` suffix exists specifically so the two `<room>.tscn` files are distinguishable by filename alone.

Rename and move files **from inside the Godot editor** (FileSystem dock), so it rewrites `uid://` references, `path=` entries and `.import` sidecars for you.

## Known gaps (not yet implemented)

- Input map (`project.godot`) currently defines `move_left`, `move_right`, `jump`, `look_up`, `look_down`, and `roll`. The design still calls for attack, open-notebook, pause, "sacar Memorina," open-map, and directional ocarina input — add these when that work actually starts, matching the existing signal-based `PlayerInput` pattern.

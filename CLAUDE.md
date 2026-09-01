# Memorina

Godot 4.7 (GDScript, Forward+ renderer), 2D metroidvania. Design source of truth lives in [`docs/design/`](docs/design/) — `01_lore_e_narrativa.md` (lore/narrative) and `02_mecanicas.md` (mechanics). Both are in Portuguese (working design language); read them for gameplay/story context before implementing a system that touches lore or mechanics.

## Architecture principles

Bias hard toward object-oriented design and SOLID/KISS. Concretely, in Godot terms:

- **Composition over inheritance.** Prefer small, single-purpose scripts wired together over deep `extends` chains. Reserve inheritance for genuinely "is-a" relationships on engine base classes; use it sparingly even then.
- **Single responsibility per script/node.** A script should do one thing. If a node's script is handling input, physics, *and* state bookkeeping, split it — see `PlayerInput` / `Player` in `Scenes/Characters/Player/` as the reference pattern: input reads `Input`/`InputEvent` and emits signals; the logic node owns state and behavior, and only reacts to those signals. Extend this same split for every future controller (guardians, enemies, UI controllers) rather than reading `Input` directly inside a logic node.
- **Signals for decoupling (Observer).** Nodes that need to react to something emit or listen to signals rather than reaching into each other via `get_node()` chains or tight parent/child coupling.
- **Resources for interchangeable data/behavior (Strategy).** Data-driven variation (e.g. per-guardian attack patterns, per-season note-sequence definitions) belongs in custom `Resource` subclasses, not in branching logic inside a single script.
- **Shallow scene trees.** If a scene's node hierarchy is growing deep to express behavior rather than actual spatial/rendering structure, that's a sign to extract a script or sub-scene instead.
- **No god-classes, no god-autoloads.** Autoload singletons are for genuinely global state (e.g. game progress) — keep them thin, delegate logic elsewhere.

## GDScript conventions

- **Static typing everywhere for new code.** Use `:` for variable/param types, `->` for return types, `:=` for inferred assignment. This is a static-typing-first codebase.
- **Naming:** snake_case for files, functions, variables; PascalCase for classes (`class_name`); CONSTANT_CASE for constants; signals in snake_case past tense (e.g. `door_opened`); private members/methods prefixed with `_`.
- **Code identifiers are English**, even where they name a design concept described in Portuguese in `docs/design/` (e.g. the "Congelar" sequence → `freeze_sequence`, not `congelar`). Keep a mental (or eventually written) glossary mapping design-doc terms to their code names as they get implemented.
- **Class body order** (official GDScript style guide): annotations → `class_name` → `extends` → docstring → signals/enums/consts → exported vars → other vars → `@onready` vars → `_init()`/static methods → virtual methods (`_ready`, `_process`, etc.) → public methods → private methods → inner classes.
- Tabs for indentation, double quotes for strings, trailing commas in multi-line literals — standard Godot style guide.

## Internationalization

**This game ships in multiple languages — build for that from the start, don't retrofit it.**

- Never hardcode user-facing strings (dialogue, UI labels, notebook text) directly in scripts or scenes. Route everything through Godot's translation system (`tr()` with a key, backed by CSV or gettext `.po` files).
- Portuguese design-doc prose is source *content* to translate, not a hardcoded default — treat every user-facing string as a translation key from the first line of code that uses it.

## Project structure

- `Scenes/Characters/<Name>/` — one folder per character, containing its scene(s) and scripts (e.g. `Scenes/Characters/Player/`).
- `resources/` — art/data assets (currently placeholders).
- `docs/design/` — design docs (lore, mechanics), source of truth for game intent.

## Known gaps (not yet implemented)

- Input map (`project.godot`) only defines `move_left`, `move_right`, `jump`. The design calls for dash, attack, open-notebook, pause, "sacar Memorina," open-map, and directional ocarina input — add these when that work actually starts, matching the existing signal-based `PlayerInput` pattern.

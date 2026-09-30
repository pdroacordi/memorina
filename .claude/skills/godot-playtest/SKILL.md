---
name: godot-playtest
description: Run an actual playtest of a Memorina gameplay area — launches the game via the tools/playtest capture harness, takes real screenshots of a scripted input sequence, and evaluates fun/fluidity/aesthetics. Use after implementing or changing anything gameplay-visible (movement, abilities, a guardian fight, HUD, seasonal art), or when the user asks to "playtest", "try the game", "see how it feels/looks", or "take screenshots" of the game.
---

# Godot playtest

This is the entry point for the project's playtesting requirement: a passing test suite
and a clean code review verify correctness, not whether the game is fun or looks right in
motion. This skill runs the game and looks.

## Procedure

1. Spawn (or continue) the `godot-playtester` agent (`.claude/agents/godot-playtester.md`)
   with a self-contained prompt naming: the area/system to test, the relevant scene path,
   which `docs/design/02_mecanicas.md` section it should feel like, and any known prior
   `docs/knowledge/playtests/` entries for the same area worth checking against.
2. The agent picks or writes a JSON input timeline, runs
   `tools/playtest/playtest_runner.tscn` via Godot (windowed, not headless — a game window
   will briefly appear and close itself), reads the resulting screenshots, and writes a
   `docs/knowledge/playtests/` entry plus any confirmed `docs/knowledge/bugs/` entries.
3. Report back: the ratings with their rationale, and any filed bug entries — link to the
   playtest report file so the user (or a future session) can open it directly.

## When not to use this

For a pure logic change with no visible/feel component (e.g. a gdUnit4-tested `RefCounted`
class with no scene involvement), a playtest adds nothing — rely on `godot-reviewer` and
the test suite instead.

## If the Godot executable can't be found

Don't guess a path or fabricate a result. Tell the user directly and ask for the path to
their Godot 4.7 executable (or have them run the harness command themselves and hand back
the output directory) — see `tools/playtest/README.md` for the exact invocation.

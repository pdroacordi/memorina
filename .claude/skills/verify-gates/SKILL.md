---
name: verify-gates
description: Run Memorina's quality gates in order - import, gdUnit4 suite, smoke test, architecture-rule scans, git hygiene - stopping at the first failure. Use before marking a roadmap item done, before every commit of code, and when the user says "verify", "run the gates", "is it green".
---

# verify-gates

Run in order and stop at the first red gate. Report each gate as PASS/FAIL with the evidence (counts, the offending lines). `$GODOT` is the console binary, set in `.claude/settings.json`; if it is empty, search for `Godot_v4.7*_console.exe` and say so.

Any `SCRIPT ERROR`, `Parse Error` or `ERROR:` in gate 1-3 output is a FAIL even when the exit code is 0. Write logs to the session scratchpad, never the repo.

## 1. Import

```bash
"$GODOT" --headless --path . --import > "$LOGS/gate_import.log" 2>&1; grep -nE "SCRIPT ERROR|Parse Error|ERROR:" "$LOGS/gate_import.log" | grep -vE "resources still in use at exit|Pages in use exist at exit"
```
Empty grep = PASS. The two filtered lines are engine shutdown leak reports that the importer prints on a clean HEAD too (measured 2026-10-02). Needed after any new `class_name` or edited `.room`.

## 2. Tests

```bash
"$GODOT" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests > "$LOGS/gate_tests.log" 2>&1; echo "exit $?"
```
Exit 0 = PASS. On failure, quote the failing suite and assertion from the log.

## 3. Smoke

```bash
"$GODOT" --headless --path . res://tools/smoke/smoke.tscn > "$LOGS/gate_smoke.log" 2>&1; echo "exit $?"
```
Exit 0 = PASS. Warnings are listed, not failed. A new playable scene must be in `tools/smoke/scenes.txt`.

## 4. Rule scans

Each must print nothing. A hit is a FAIL unless the line is a documented exception; then say which.

```bash
X="--exclude-dir=addons --exclude-dir=.godot"
# Input is read only by the input nodes (CLAUDE.md: Architecture principles).
grep -rnE '\bInput\.(is_|get_|action)' --include=*.gd $X scenes globals resources | grep -vE 'player_input\.gd|input_device\.gd'
# WorldFreeze is the only writer of Engine.time_scale and get_tree().paused.
grep -rnE 'Engine\.time_scale\s*=|get_tree\(\)\.paused\s*=' --include=*.gd $X . | grep -v 'world_freeze.gd'
# Shaders: game-pixel space, never FRAGCOORD; pausable clocks, never TIME (greyhush edge reroll is the one exception).
grep -rnE '\bFRAGCOORD\b' --include=*.gdshader --include=*.gdshaderinc $X . | grep -vE ':\s*//'
grep -rnE '\bTIME\b' --include=*.gdshader --include=*.gdshaderinc $X . | grep -vE ':\s*//|greyhush_common\.gdshaderinc'
# Clip names are resolver consts, never loose literals.
grep -rnE '(travel|play)\(&?"' --include=*.gd $X scenes
# User-facing text goes through tr() keys.
grep -rnE '^text = "[A-Za-z]' --include=*.tscn $X scenes
grep -rnE '\.text\s*=\s*"[A-Za-z]' --include=*.gd $X scenes globals
# No commented-out code.
grep -rnE '^\s*#\s*(var|func|if|for|while|return|await|print)\b' --include=*.gd $X scenes globals resources tools tests
```

## 5. Git hygiene

`git status --short` must not list `.godot/`, `*.tmp`, `reports/`, playtest output or `.claude/settings.local.json`. Only the files this change touched should be modified.

## 6. Visible changes

If the change is gameplay-visible (movement, abilities, a fight, HUD, art, the Memorina), the gates are not enough: run the `godot-playtest` skill and read the screenshots.

Only report "green" when every gate ran and passed. If a gate was skipped, say which and why.

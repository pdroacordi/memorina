---
id: gotchas/a-replaced-sheet-plays-the-old-import-until-reimported
type: gotcha
title: A sprite sheet replaced on disk keeps its old import in a game run, so new hframes slice the old texture
status: active
tags: [import, sprite-sheet, playtest, animation, godot-4.7, story-10]
related: [systems/animation, playtests/2026-10-15-story10-guitar, gotchas/a-failed-import-is-cached-and-not-retried]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - assets/sprites/characters/ivo/ivo_guitar.png
  - tools/playtest/playtest_runner.gd
---

# A replaced sheet plays the old import until reimported

**Measured in 4.7.2 (STORY-10).** Running the game (`--path . <scene>`, the playtest runner included) loads
`.godot/imported/<file>.ctex` as it is; it does not reimport a PNG that changed on disk. Headless gdUnit runs
load the same stale texture.

Seen when `ivo_guitar.png` went from 2 frames (256x128) to 6 (768x128) and the clips were keyed to 6 hframes:
the playtest sliced the old 256 px texture into six 42 px strips, and Ivo vanished in four of the six frames
(a strip of empty frame margin). `ivo_sheet_test` and the Sprite2D state (frame, hframes, texture path) looked
right; only the screenshots showed it.

**Prevention:** run `"$GODOT" --headless --path . --import` after any asset on disk changes, before tests or
a playtest. A ctex older than its PNG (`ls -l --time-style=full-iso`) means the import is stale.

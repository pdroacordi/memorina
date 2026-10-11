---
id: systems/foreground
type: system
title: Foreground - art in front of the creatures, greyed by the same pass, faded while someone stands behind it
status: active
tags: [foreground, rendering, subviewport, canvas-pass, greyhush, parallax, fade, lesson]
related: [architecture/foreground-layer, systems/greyhush, systems/seasonal-art, systems/water, systems/backdrops, playtests/2026-10-09-foreground]
created: 2026-10-09
updated: 2026-10-11
source_files:
  - scenes/world/memory/canvas_pass.gd
  - scenes/world/environment/foreground/foreground_piece.gd
  - scenes/world/environment/foreground/foreground_math.gd
  - scenes/ui/lesson_cinematic/lesson_dim.gdshader
  - scenes/world/game.tscn
---

# Foreground

**Never break:** a foreground piece draws only in `ForegroundPass` (visibility bit 4), composited after `Creatures` by the creature composite's shader; never in the root canvas. Each `CanvasPass` owns its bit of the root's `canvas_cull_mask`; nothing else writes it.

Design 04 section 6, MEM-12. Plan and options: `architecture/foreground-layer`.

- **Two passes, one class.** `CanvasPass` (`canvas_pass.gd`, formerly `creature_mask.gd`) renders one visibility bit of the shared world into a texture published as a shader global: `CreatureMask` (bit 2, `greyhush_creature_pass`) and `ForegroundPass` (bit 4, `greyhush_foreground_pass`), both ALWAYS, both mirroring the root's canvas transform. Each removes its bit from the root in `_ready` and restores it in `_exit_tree`. `CanvasPass.join_layer(item, bit)` puts an item on a pass and adds the bit to its ancestors.
- **Composite.** `CanvasLayer` order: `Greyhush`, `Creatures`, `Foreground` (TextureRect of the foreground pass, `greyhush_foreground_material.tres`, the creature shader with `clipped_pass` false, so a clipped shield lights the creature but not a pillar in front of it), then `LessonCinematic` and the HUDs. `GreyhushRenderer` pushes every field uniform to both composites (`foreground_pass_path`).
- **The lesson.** `LessonCinematic` now sits above both passes; its `Dim` (`lesson_dim.gdshader`) cuts a hole where a creature shows uncovered: `a *= 1 - creature.a * (1 - front.a)`. The bars and the title card cover everything.
- **A piece.** `ForegroundPiece` (Sprite2D) under a plain `Foreground` Node2D in a room's contents scene, nearest piece last; its parent has no rotation or scale. `scroll_scale` 1..2 crosses the screen that many times as fast as the world (`ForegroundMath.parallax_offset`, from the view centre, so a region's placement never matters). `reveals` fades the whole piece to `faded_alpha` (0.3) over `fade_time` (0.25 s, scaled time: a hold freezes it) while any `Character.CHARACTERS_GROUP` body's `body_rect()` is covered by at least `reveal_coverage` (15%) of the piece's `reveal_rect`. Pieces are ALWAYS, like the passes they follow.
- **Water** never reflects the foreground: the pass is in neither the screen copy nor the creature pass.
- **Art contract:** `architecture/foreground-layer`, "Art contract" (1x, binary alpha, nature pieces three season bands, built pieces one; near pieces at most 640x240 per band; at most about 20% of a frame; never over a landing, bench, door or song interactable).
- **Secret walls** (`architecture/secret-false-walls`): `SecretWall`'s `Front_*` layers are the second kind of foreground item: tiles, no parallax, z -1, drawn only in `ForegroundPass`; their world twin (z 40) is what water reflects. The "never over a landing, bench, door or song interactable" art rule is `ForegroundPiece`'s; a secret may hide those because it opens when Ivo's body enters it.
- **Helix stairs** (`systems/helix-stair`) draw nothing in `ForegroundPass`. The tower is one `HelixView` sprite at z -15 in the world canvas, behind Ivo. The 2026-10-11 revision dropped the near-run cover (`architecture/walkable-helix-stair`, Revision).
- **Today.** Two flat placeholders in the spring trial (`assets/sprites/world/foreground/demo/`): a column at Ivo's depth (fades) and a near branch at 1.4. Measured: `playtests/2026-10-09-foreground`.

---
id: bugs/the-seed-shop-panel-draws-under-the-greyhush-and-the-creature-composite
type: bug
title: The seed shop panel shares the HUD's canvas layer 1, so the Greyhush pass greys and vignettes it and Ivo's creature composite draws over it
status: resolved
severity: medium
tags: [life-04, seed-shop, ui, canvas-layer, greyhush, creatures, foreground, rendering]
related: [playtests/2026-10-28-life04-seeds-and-seller, systems/seeds-and-the-seller, architecture/season-seeds-and-the-seller, systems/greyhush, systems/foreground, gotchas/screen-texture-copy-scope, gotchas/canvas-layers-on-one-layer-index-stack-by-sibling-index-not-tree-order]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/world/story/seed_shop_beat.tscn
  - scenes/ui/seed_shop/seed_shop_panel.tscn
  - scenes/world/game.tscn
  - scenes/world/memory/greyhush.gdshader
---

## Summary

ACTIVE (LIFE-04 review, 2026-10-28; reasoned from the scenes and the shader, not seen in a run, because the shop was not playtested). `SeedShopBeat`'s `Layer` CanvasLayer keeps the default `layer = 1`, the same layer as `Game/CanvasLayer`. That layer starts with the full-screen `Greyhush` ColorRect, then the `Creatures` and `Foreground` composites. The panel is drawn first, so the greyhush pass re-shades it and Ivo and the seller are drawn over it.

## Symptom

1. Ivo holds a seed and talks to the seller in `village_lane_west`. The talk reaches `seller_shop` and `SeedShopPanel.open()` shows the panel (pack x 64..256, the middle of the screen).
2. The panel is part of the screen the `Greyhush` pass reads (`greyhush.gdshader:10`, `hint_screen_texture`). The pass writes every pixel back with alpha 1 (`:22`). Where the village's memory is grey, the wood box, the row text and the seed icons are desaturated, dithered in game pixels and vignetted, like the world under them.
3. The `Creatures` TextureRect comes after `Greyhush` on the same layer and draws over the panel. Ivo stands at the seller, near the screen centre, so his sprite covers the rows. The `Foreground` composite also covers any foreground piece in view.
4. The `DialogueBox`, which lives in `Game/CanvasLayer` after these three nodes, never has this problem. The shop is the first UI drawn on a canvas layer outside that node.

## Seen in play (LIFE-04 playtest, 2026-10-28)

Confirmed in every shop frame of `tools/playtest/scripts/life04_shop_en.json` and `life04_shop_pt_BR.json`, at both memory levels tried:
- Ivo's sprite is drawn over the rows "A rumour" and "Replant the village" (`playtests/screenshots/2026-10-28-life04-seeds-and-seller/shop_open_en_ivo_over_panel.png`). The street's grass blades also draw over the panel as a row of green dots at Ivo's feet. The seller is hidden under the panel.
- The panel's paper is re-shaded by the world. `bg_box_wood.png`'s paper is (208, 156, 142). The dialogue box draws it exactly; the shop panel draws (177, 153, 137) at the runner's default village memory and (175, 159, 151) with two guardians restored (0.6). A UI colour that follows the world's memory is this bug.
- The panel still works: focus, buys and Leave all behave.

## Root cause

- `scenes/world/story/seed_shop_beat.tscn:10` declares `[node name="Layer" type="CanvasLayer"]` with no `layer`, so it uses 1. `Game/CanvasLayer` (`game.tscn:182`) also uses 1.
- Godot documents the order of two CanvasLayers with the same `layer` as unspecified. In practice the engine passes each layer's sibling index as its sublayer (`viewport_set_canvas_stacking(..., layer, get_index())`). The shop's `Layer` is child 0 of `SeedShopBeat` and `Game/CanvasLayer` is child 6 of `Game`, so the shop is drawn first (`gotchas/canvas-layers-on-one-layer-index-stack-by-sibling-index-not-tree-order`).
- The plan accepted "drawn under the HUD and the Fade (same layer, earlier in the tree)" (`architecture/season-seeds-and-the-seller`, "As built"). It did not account for `Game/CanvasLayer` also holding the greyhush pass and the two composites, which redraw the whole screen.

## Fix

Not fixed. The panel must be drawn after `Foreground` and before `ScreenLayer` (layer 2), with a stacking that does not rely on the unspecified same-layer order. Options for the owner:
- Give the shop `Layer` its own index between the two. This needs `ScreenLayer` raised to 3 (and anything else that checks layer numbers), so the pause menu still opens over the shop.
- Or instance the panel under `Game/CanvasLayer` after `DialogueBox`, as the box is placed, with the beat holding a NodePath or a Game-set reference. This costs a little coupling and avoids a new layer number.

Whichever is chosen, `Fade` and `Letterbox` should stay above the panel (they are below it today only if the unspecified order goes the other way).

## Prevention

- Any UI drawn while the world shows sits in `Game/CanvasLayer` after `Foreground`, or on a CanvasLayer whose `layer` is strictly greater than 1. Never use the same layer as the greyhush pass.
- Playtest a new panel over a grey room, with Ivo under it, before marking it done. A headless suite cannot see a draw order.

## Resolution (2026-10-28)

The beat's `Layer` is CanvasLayer layer 2, over the world's layer 1 (greyhush pass, composites, HUD); `ScreenLayer` moved from 2 to 3 so the pause menu stays over the shop. `seed_shop_beat_test.test_the_panel_draws_between_the_world_and_the_menus` pins the order.

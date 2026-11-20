---
id: bugs/a-spawns-overdrawn-pixels-lose-the-self-lit-mark-and-grey
type: bug
title: Every spawn pixel drawn over another of its own pixels loses the self-lit mark, so the light half of each placeholder spawn and every floor-warning line still greys
status: fixed
severity: medium
tags: [grd-18, guardians, spawns, greyhush, self-lit, creature-pass, alpha-mark, blending, rendering]
related: [systems/greyhush, systems/guardians, gotchas/canvas-blend-mix-accumulates-alpha-so-an-overdrawn-alpha-mark-is-lost, bugs/ivos-greyhush-shield-colours-a-creature-in-melee-range]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/characters/guardians/spawns/spawn_self_lit.gdshader
  - scenes/world/memory/self_lit_mark.gdshaderinc
  - scenes/world/memory/greyhush_creatures.gdshader
  - scenes/characters/guardians/spawns/spawned_attack.gd
---

## Symptom

Found in the GRD-18 review (2026-11-20), by reading and arithmetic; not seen in a run.
In a grey arena, the pixels that a spawn draws over its own earlier pixels are greyed by the
field, and only the pixels drawn once keep the guardian's colour:

- the floor warning (`SpawnedAttack.draw_floor_warning_on`, `spawned_attack.gd`): the light
  line and the light sparks are drawn inside the dark rim and dark sparks, so the light parts grey
  and only the dark rim stays coloured;
- every placeholder spawn of the Frost, Leaf, Sun and mentor kits (`boomerang.gd:67-68`,
  `falling_shard.gd:35-52`, `floor_shadow.gd:27-41`, `leaf_swirl.gd:36-37`,
  `light_column.gd:23-33`, and the `FloorRunner`/`Lob`/`FloorPatch` placeholders): each draws a
  light rect over a dark one (or dark edges over light), so its inner half greys;
- Bloom's seed pod over its own landing warning near the floor.

Bloom's drawn spikes and tufts are unaffected: their frames tile edge to edge without overlap.
This defeats the user decision "Keep the guardian's colour (Recommended)" (2026-11-19) for most
of what a spawn draws.

## Root cause

`spawn_self_lit.gdshader` has no `render_mode`, so it blends with `blend_mix`, whose alpha
equation is `a = src.a + dst.a * (1 - src.a)`. A marked pixel (254/255) over a marked pixel gives
`254/255 + 254/255 * 1/255 = 0.999985`, stored as 255 in 8-bit and as 1.0 in half float.
`gh_is_self_lit` (254 +- 0.5) then fails, so `greyhush_creatures.gdshader` shades it as a normal
pixel with the field's memory. The unshielded mark (253) never met this because the corruption
edge is one sprite quad; a `SpawnedAttack` issues several `draw_rect`/`draw_texture_rect_region`
calls on one canvas item, and each blends over the last. The docs' accepted leak ("an opaque pixel
drawn over it clears it") does not cover a spawn overdrawing itself.

The same arithmetic clears the mark wherever a spawn draws over any opaque creature-pass pixel
(the guardian's body, Ivo).

## Fix (applied 2026-11-20)

`spawn_self_lit.gdshader` now has `render_mode blend_disabled;`, `discard`s below alpha 0.5, and writes
`vec4(COLOR.rgb * GH_SELF_LIT_ALPHA, GH_SELF_LIT_ALPHA)`: premultiplied, as `blend_mix` leaves an opaque pixel on the
transparent pass (rgb x a, a), which the creature composite unpremultiplies. Each primitive replaces the one under it,
so the last draw wins and the alpha stays exactly 254/255. A spawn pixel now also replaces any creature-pass pixel
under it (the guardian's body, Ivo) instead of blending over it; both are opaque, so nothing visible changes.

Measured in game (`tools/playtest/scripts/guardian_fight_player_driver.gd`, `PL_GOD=1`, screenshots at 1280x720,
2026-11-20), composite colours read from the screenshots:

- Bloom thorn row's floor warning (light `(0.78, 0.86, 0.62)` = 199,219,158; dark rim 51,66,41), grey arena,
  1.6 s into the fight. Before: rim (48, 65, 38), light line (188, 196, 183), spread 13 (greyed). After: rim
  (48, 65, 38), light line (187, 214, 147), spread 67 (coloured; the base vignette darkens it about 5 %).
- Frost icicle (`FallingShard`, light `(0.86, 0.94, 1.0)` = 219,240,255; dark `(0.12, 0.18, 0.28)` = 31,46,71),
  91.5 s in, in the drained lake arena (background spread 13-18): body light (211, 235, 254), spread 43; dark rim
  (29, 45, 71); its floor warning's light line (211, 235, 254). Greyed, that light would be about luma 235 with a
  spread near 0.

No rendered regression test: the suite runs headless on the dummy renderer, which draws nothing, so a SubViewport
cannot be read back. `spawned_attack_test.test_every_kind_draws_self_lit_in_the_creature_pass` pins the fix instead:
every kind's material is the self-lit one and its shader code contains `blend_disabled`.

## Prevention

- An exact-alpha mark written by a canvas item that draws more than one primitive must be written
  with `blend_disabled`; `gotchas/canvas-blend-mix-accumulates-alpha-so-an-overdrawn-alpha-mark-is-lost`.
- `spawned_attack_test.test_every_kind_draws_self_lit_in_the_creature_pass` now also checks that
  the shader's code contains `blend_disabled`, for every kind (`floor_shadow` and `leaf_swirl` included).

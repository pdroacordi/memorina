---
id: gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid
type: gotcha
title: STRETCH_KEEP_ASPECT_CENTERED offsets by half the leftover, unrounded, so a 2x portrait whose width is 2 mod 4 sits half an art pixel off the box
status: active
tags: [texture-rect, stretch-mode, pixel-grid, 2x-rule, portrait, ui, dialogue]
related: [systems/dialogue, systems/screens]
created: 2026-10-16
updated: 2026-10-16
source_files:
  - scenes/ui/dialogue_box/dialogue_box.tscn
  - assets/sprites/hud/portraits/
---

## Summary

A `TextureRect` with `STRETCH_KEEP_ASPECT_CENTERED` centres the scaled texture at
`(size - drawn) / 2` without rounding. In the dialogue box's 48x48 slot under the 2x `Art`
root, a 96 px tall pixel-doubled portrait of width `w` starts `(96 - w) / 2` viewport px
from the slot's left edge. When `w` is 2 mod 4 that is odd, so every art pixel straddles the
panel's 2x grid by one viewport px. Nothing blurs; the portrait is offset from the frame.

## Details

- Measured in 4.7.2 (UI-13 review, 2026-10-16), windowed, 640x360, a TextureRect at (18, 116)
  48x48 under a scale-2 Control: first drawn column at viewport x 36 + 15 for
  `water_carrier.png` (66 px wide), + 7 for `taverner.png` (82), + 13 for `daughter.png`
  (70); + 12, 6, 14, 12 and 0 for the 72, 84, 68, 72 and 96 px wide portraits.
- `mentor.png` (86) has the same offset, + 5.
- UI-13 padded `water_carrier`, `taverner`, `daughter` and `mentor` with one transparent art-px
  column on the left (now 68, 84, 72, 88 wide); every portrait's width is a multiple of 4.
- The vertical axis is unaffected while every portrait is 96 px tall. `elder_model.png`
  (96x76) is centred vertically by 5 art px, which is a whole art pixel.

## Gotchas / pitfalls

- To land on the grid, cut a 96 px tall portrait at a width that is a multiple of 4 (an even
  number of art px), or pad it with one transparent art-px column.
- `snap_2d_transforms_to_pixel` does not help: it snaps transforms, and the offset is a whole
  viewport pixel already. It is half of an art pixel.

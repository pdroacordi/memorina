---
id: guardian_frost_effect_icicle
command: generate
target: res://assets/sprites/characters/guardians/frost_guardian/effects/frost_icicle.png
size: 16x28
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
An icicle of the icicle fall (`icicle.tscn`, a `FallingShard`; also the mentor's icicles): a lump of stone-blue ice tapering to a point, pale ice with a white ridge and a dark rim. Frames: forming small, forming, whole, whole with a white glint beside its top. Measured: the hit is 12x24, so the body is 12x24 (6x12 art px) under 4 px (2 art px) of room for the glint: one frame is 16x28 (8x14 art px), drawn top-aligned so it grows down from where it hangs. `FallingShard` draws its bottom at `-drop` while it forms (the stage by the warning's progress, `FallingShard.icicle_frame`, the glint frame on the placeholder's 16 Hz beat once whole) and at the tip while it falls. Colours are the golem's own, sampled from `tools/art/sources/guardians/frost_still.png` (the darkest stone as the rim). GRD-18.
Drawn by `python -I tools/art/draw_guardian_effects.py frost`. Approved: "Approve and wire (Recommended)" (user, 2026-11-20, the Frost GRD-18 sheet).
Negative: black outline, speckle, scenery, text

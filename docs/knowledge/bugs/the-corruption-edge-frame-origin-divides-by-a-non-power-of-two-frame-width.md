---
id: bugs/the-corruption-edge-frame-origin-divides-by-a-non-power-of-two-frame-width
type: bug
title: The corruption edge finds a texel's frame with floor(texel / frame_size), which can land one frame early at each frame's first column (96 and 80 are not powers of two)
status: resolved
severity: low
tags: [core-13, creatures, shader, corruption-edge, glsl, precision]
related: [gotchas/glsl-floor-division-modulo-can-return-the-divisor, systems/creatures]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/components/corruption/corruption_edge.gdshaderinc
  - scenes/characters/components/corruption/corruption_edge.gdshader
---

## Summary

`ce_frame_origin` (`corruption_edge.gdshaderinc:44-45`) returns `floor(texel / frame_size) * frame_size`.
On a texel whose x is an exact multiple of the frame width (96 for the boar, 80 for the scorpion),
GLSL may compute `texel / frame_size` as `x * rcp(96)` and land just under the integer. `floor` then
names the previous frame. This is the precision trap documented in
`gotchas/glsl-floor-division-modulo-can-return-the-divisor`. Latent: no current strip has an opaque
pixel in a frame's first or last two texel columns, so nothing shows today.

## Details

- With the wrong origin, the frame-local art x for texel `96k` is 48 (40 for the scorpion).
  `ce_inside` then rejects that pixel, so `CE_EDGE` treats an opaque pixel there as interior,
  never frayed. The stray loop in `corruption_edge.gdshader:26-32` can also read the previous
  frame's last art column: with the scorpion's drift (1, -1), the source for art x 40 is the
  previous frame's x 39.
- Checked 2026-10-29 with PIL. Every boar and scorpion strip has 0 opaque pixels (alpha >= 128)
  at frame column 0 and in the last two columns, so the wrong origin draws nothing different
  yet. A round-2 strip with art touching a frame edge would show it: one column that does not
  fray, or a stray borrowed from the neighbouring frame.
- Only the x axis is at risk. Frame heights are 64 (a power of two, so exact), and the divisor
  `art_scale` is 2.

## Fix

Not applied. Divide from the texel's centre so the quotient sits half a texel clear of the
integer: `floor((texel + 0.5) / frame_size) * frame_size`.

## Prevention

Any `floor(a / n)` in a shader with a non-power-of-two `n` and integer-valued `a` needs the
half-texel offset, or `n` must be a power of two.

## Resolution (2026-10-29)

`ce_frame_origin` divides from the texel centre: `floor((texel + 0.5) / frame_size)`.

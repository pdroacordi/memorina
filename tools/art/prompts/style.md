---
preamble: minimalist 16-bit pixel art for a 2D side-view metroidvania set in a lived-in medieval valley, crisp hard pixels, no anti-aliasing, no smooth gradients, simple flat shapes with clear silhouettes and few details, limited palette of about 16 colours, base colours at MEDIUM brightness, no outlines, no baked lighting, glow or cast shadows, no text
negative: blurry, anti-aliased, smooth gradient, photorealistic, painterly, 3d render, text, watermark, signature, background scenery, frame border, cropped, noisy dithering, busy texture, speckle, neon colours, black outline, outlines, baked lighting, very dark image
---
The shared preamble every generator prompt in this library is appended to
(tools/pixellab/pixellab.ps1 -Prompt, the codex-consult image mode). Change it
here, never per entry, so the whole game keeps one look.

**One pixel density** ("One 2x pixel density + Orbita-style rules (Recommended)",
user, 2026-10-10): every piece of art is drawn at 2x, so one art pixel is 2x2
game pixels - the density Ivo's sprites already have. A 32 px tile is drawn at
16 art px, a 96 px sprite at 48. Mixing densities (a 2x character on 1x ground)
reads as wrong however good each piece is; `systems/art-pipeline` has the rule
and the tools (`art_scale` in a recipe).

**Minimal, no outlines** ("I think now it is kind of too polluted visually. Maybe give it a slightly more minimastic look? Also, take out the black outline (i don't like it), no outlines.", user, 2026-10-10): flat shapes, few colours per surface, no speckle, and no outline on anything; a face is marked only by a soft shade.

**The rules, after FAG-orbita's pipeline** (the user's reference, 2026-10-10):
- 16-bit pixel art, crisp hard pixels, a limited palette per biome (about 16
  colours), named in the entry.
- Base colours at medium brightness, no baked lighting, glow or cast shadows:
  the greyhush and the seasons light the scene at runtime, and a dark image
  turns into a black mass on screen.
- Generate small: at most 4x the final art size, then reduce by averaging. A
  big image shrunk to pixel art comes out blurry.
- Flat magenta (`#FF00FF`) background for stills; a sheet is a grid of
  separate pieces, never a composed scene; a tile is filled edge to edge.

The approved look is `tools/art/references/village_concept.png` (Codex, our own
art; the user, 2026-10-08: "Yes, aim for this"): the village street at memory
0.8 - half-timbered houses, warm lit windows, cobbles with moss in the joints,
deep layered hills and snowy mountains, life on the street. It may be given to
a generator as a style reference; pack art never may (CREDITS.md).

Palettes are per biome ("Rewrite to the concept, palette per biome", user,
2026-10-08): each biome's palette is extracted from its approved style board
into `tools/art/palettes/<biome>.json`; `tools/art/palette.json` stays for the
song trials' pack-derived art. Art must still read in silhouette and value,
because a forgotten pixel keeps only those (systems/greyhush).

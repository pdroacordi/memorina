---
preamble: 2D side-view pixel art for a melancholic, lived-in medieval metroidvania, crisp 1:1 pixels, detailed warm painterly pixel shading with 3 to 4 tone ramps, rich but harmonious earthy palette - dark soil and oak browns, mossy and sage greens, warm amber lamplight, cool slate-blue shadows, weathered stone greys - readable silhouette, dark brown outline on foreground objects, no anti-aliasing, no smooth gradients, no text
negative: blurry, anti-aliased, smooth gradient, photorealistic, 3d render, text, watermark, signature, background scenery, floor, frame border, multiple objects, cropped, noisy dithering, neon colours, pure black outline
---
The shared preamble every generator prompt in this library is appended to
(tools/pixellab/pixellab.ps1 -Prompt, the codex-consult image mode). Change it
here, never per entry, so the whole game keeps one look.

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

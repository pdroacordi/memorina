---
id: backdrop_interior_timber_wall
command: generate
target: res://assets/sprites/world/background/interior_timber/wall.png
size: 512x512
frames: 1
source: codex
---
The backdrop wall of `resources/world/backdrops/interior_timber.tres`: the inside wall of a half-timbered house: warm plaster crossed by dark oak timber framing (posts, rails and cross braces). Opaque, repeats on both axes, one band (no seasons underground or indoors), drawn at 2x. The plaster is lighter than the oak plank ground, the one exception to the darker far wall of architecture/backdrop-seams ("Art contracts"): the dark planks read against it by contrast. Codex drew a square seamless texture (prompt: minimal 16-bit, large flat shapes, timber framing on plaster, low contrast), kept in tools/art/sources/backdrop_interior_timber_codex.png; cut by `python -I tools/art/cut_wall.py tools/art/sources/backdrop_interior_timber_codex.png assets/sprites/world/background/interior_timber/wall.png --tile=256 --levels=4 --flat=#5b3e2a,#978364 --edge=#8c785b`: reduced to 128 art px and repeated, each wrap stitched along the cut of least difference, then two flat tones (timber #5b3e2a, plaster #978364) with a one-pixel #8c785b line along the timber. The warm two-tone replaced the grey five-value cut so the interiors read as lived-in rooms behind the props ("The house interiors tiles could be improved as well as their design", user, 2026-10-10; boards "Approve as shown (Recommended)", 2026-10-11).
Negative: outlines, perspective, light source, glow, vignette, border, objects, creatures, text, speckle, high contrast

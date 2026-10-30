---
id: guardian_summer_hurt
command: generate
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_hurt.png
size: 192x96
frames: 7
view: side
direction: west
no_background: true
source: procedural: tools/art/lean_frames.py
---
A stagger, 0.5833 s at 1/12 s a frame, 7 frames. The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row (Sprite2D y -96). Sheets are 1 px per art px, shown at Sprite2D scale 2; 192x96 frames, so it animates at 1x like Frost. The flip axis (the frame's middle, x 96) is the torso's centre midway between the fore and hind legs, so the head reaches about 42 art px forward of it and the tail about 57 back. The still is our own: tools/art/sources/guardians/sun_lion_still.png (99x64 art px), cut from the Codex concept tools/art/sources/guardians/sun_lion_concept_codex.png (variant A, the left lion; user, 2026-10-30: "A, pesado (Recommended)"). The reference is the still padded onto the 192x96 frame with its legs' centre on the frame's middle (`python -I tools/art/pad_reference.py tools/art/sources/guardians/sun_lion_still.png tools/art/sources/guardians/sun_lion_ref.png 192x96 --at=bottom --axis=42`). `python -I tools/art/lean_frames.py tools/art/sources/guardians/sun_lion_ref.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_hurt.png --pivot=78 --lean=0,6,10,9,7,4,1` leans the still back above art row 78 (the knees): the mane and tail are thrown 6, 10, 9, 7, 4 and 1 art px away from the facing (toward +x) and recover; the legs stay planted. Procedural as for Frost (`systems/art-pipeline`: every generated recoil carried an effect); no PixelLab call. No pack art was shown to any generator; every reference is our own still or our own GRD-04 strip.
Negative: outlines, black contour, front view, facing right, facing the viewer, turning around, glow, flash, fire, sparks, particles, motion lines, text, ground, scenery

---
id: guardian_summer_walk
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_walk.png
size: 192x96
frames: 8
keep: 0-7
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: walk: the heavy stone lion walks forward to the left with slow heavy padding steps, its four legs moving in a lion's walking gait, head low, tail hanging behind, a looping walk cycle in place, side view facing left the whole time, keeping the same angle as the first frame in every frame
source: pixellab
---
A walk loop, 1.0 s at 0.125 s a frame (a heavy pad). The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row (Sprite2D y -96). Sheets are 1 px per art px, shown at Sprite2D scale 2; 192x96 frames, so it animates at 1x like Frost. The flip axis (the frame's middle, x 96) is the torso's centre midway between the fore and hind legs, so the head reaches about 42 art px forward of it and the tail about 57 back. The still is our own: tools/art/sources/guardians/sun_lion_still.png (99x64 art px), cut from the Codex concept tools/art/sources/guardians/sun_lion_concept_codex.png (variant A, the left lion; user, 2026-10-30: "A, pesado (Recommended)"). The reference is the still padded onto the 192x96 frame with its legs' centre on the frame's middle (`python -I tools/art/pad_reference.py tools/art/sources/guardians/sun_lion_still.png tools/art/sources/guardians/sun_lion_ref.png 192x96 --at=bottom --axis=42`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_walk -Out tools/art/sources/guardians`; the returned frames kept in tools/art/sources/guardians/guardian_summer_walk/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_walk guardian_summer_walk tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_walk.png --scale=1 --keep=0-7 --floor=95 --centre=84-96`, then `python -I tools/art/despeckle.py assets/sprites/characters/guardians/summer_guardian/summer_guardian_walk.png 192`. Every pixel is snapped to the still's 16 colours. A slow pad in place, head low on frames 3-7; returned frame 8 repeats 0. It stays in profile (no turn to the viewer, the tail kept on every frame). No pack art was shown to any generator; every reference is our own still or our own GRD-04 strip.
Negative: outlines, black contour, front view, facing right, facing the viewer, turning around, glow, flash, fire, sparks, particles, motion lines, text, ground, scenery

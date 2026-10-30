---
id: guardian_summer_leap
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_leap.png
size: 192x96
frames: 8
keep: 1-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: big jump: the stone lion crouches low on all four legs, then springs up into the air with its front legs stretched forward and hind legs stretched back, body arched, then lands hard on its front paws and hind paws in a crouch, then stands up, side view facing left the whole time
source: pixellab
---
The lucidity leap, 8 frames (crouch 0-1, 0.3 s; rise 2-3; fall 4-5; land 6-7, 0.3 s). The flight is the guardian's own motion, so every frame keeps its feet on the floor row and the clip holds or loops its flight frames until the landing. The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row (Sprite2D y -96). Sheets are 1 px per art px, shown at Sprite2D scale 2; 192x96 frames, so it animates at 1x like Frost. The flip axis (the frame's middle, x 96) is the torso's centre midway between the fore and hind legs, so the head reaches about 42 art px forward of it and the tail about 57 back. The still is our own: tools/art/sources/guardians/sun_lion_still.png (99x64 art px), cut from the Codex concept tools/art/sources/guardians/sun_lion_concept_codex.png (variant A, the left lion; user, 2026-10-30: "A, pesado (Recommended)"). The reference is the still padded onto the 192x96 frame with its legs' centre on the frame's middle (`python -I tools/art/pad_reference.py tools/art/sources/guardians/sun_lion_still.png tools/art/sources/guardians/sun_lion_ref.png 192x96 --at=bottom --axis=42`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_leap -Out tools/art/sources/guardians`; the returned frames kept in tools/art/sources/guardians/guardian_summer_leap/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_leap guardian_summer_leap tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_leap.png --scale=1 --keep=1-8 --floor=95`, then `python -I tools/art/despeckle.py assets/sprites/characters/guardians/summer_guardian/summer_guardian_leap.png 192`. Every pixel is snapped to the still's 16 colours. Crouch (0), spring with the forelegs up (1-2), stretched flight (3-5), forepaws reaching to land (6), standing (7). Uncentred: centring the stretched flight frames on a band of rows moved the crouch off the axis; the flight frames drift up to ~15 art px forward, the leap's own direction. No pack art was shown to any generator; every reference is our own still or our own GRD-04 strip.
Negative: outlines, black contour, front view, facing right, facing the viewer, turning around, glow, flash, fire, sparks, particles, motion lines, text, ground, scenery

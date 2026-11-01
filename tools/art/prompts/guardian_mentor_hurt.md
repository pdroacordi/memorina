---
id: guardian_mentor_hurt
command: generate
target: res://assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_hurt.png
size: 128x96
frames: 7
view: side
direction: west
no_background: true
source: procedural: tools/art/lean_frames.py
---
A stagger, 0.583 s at 1/12 s a frame. The mentor as a guardian, the final battle (GRD-06, `architecture/grd-06-final-battle` section 6): the guardian of the crack and the most corrupted of all (design 02 section 5), a tall old man in a long hooded robe of lichen and moss flecked with snow, a pale mask-like face under the hood, the robe trailing behind him; in the fight he is grey and stiff, in the stasis still's eight flat greys, and he has no flute (he gave it to Ivo). Seen from the side facing west, the robe's middle under the head on the flip axis, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (128x96), shown at Sprite2D scale 2; the body is 43x60 art px, the story still's 86x120 game px. The stills are our own: assets/sprites/world/story/mentor/stasis.png (grey) and empty_hand.png (colour, the plan's reference), both at 2x density and pixel for pixel the same figure. The grey reference is `python -I tools/art/pad_reference.py assets/sprites/world/story/mentor/stasis.png tools/art/sources/guardians/mentor_grey_ref.png 256x192 --at=bottom --axis=34`, the colour one the same command on empty_hand.png (mentor_colour_ref.png): still column 34 on the flip axis; PixelLab animates the 2x still and the cut halves it (systems/art-pipeline, Guardians). The grey reference at 1x (mentor_grey_ref.png halved, nearest: tools/art/sources/guardians/mentor_grey_ref_1x.png) is leaned back above the hips by `python -I tools/art/lean_frames.py tools/art/sources/guardians/mentor_grey_ref_1x.png assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_hurt.png --pivot=72 --lean=0,6,10,9,7,4,1`: the hood, head and raised arm are thrown 6, 10, 9, 7, 4 and 1 art px away from the facing (toward +x) and recover; the robe's foot stays planted. Procedural, as every GRD-04 hurt, because generated recoils paint effects in the body's colours (systems/art-pipeline). No generation. No pack art was shown to any generator; every reference is our own still or our own strip of this guardian.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, flute, text, ground, scenery

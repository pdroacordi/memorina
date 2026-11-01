---
id: guardian_mentor_walk
command: animate3
target: res://assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_walk.png
size: 128x96
frames: 8
keep: 0-7
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/mentor_grey_ref.png
action: walking: the tall old hooded man in a long grey robe walks forward to the left with long clear strides, his weight shifting from foot to foot, his long robe swinging around his legs with each step, his free arm swinging and his raised hand moving with the steps; side view facing left the whole time
source: pixellab
---
A walk loop, 1.0 s at 0.125 s a frame: a stiff, heavy dragging step. The mentor as a guardian, the final battle (GRD-06, `architecture/grd-06-final-battle` section 6): the guardian of the crack and the most corrupted of all (design 02 section 5), a tall old man in a long hooded robe of lichen and moss flecked with snow, a pale mask-like face under the hood, the robe trailing behind him; in the fight he is grey and stiff, in the stasis still's eight flat greys, and he has no flute (he gave it to Ivo). Seen from the side facing west, the robe's middle under the head on the flip axis, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (128x96), shown at Sprite2D scale 2; the body is 43x60 art px, the story still's 86x120 game px. The stills are our own: assets/sprites/world/story/mentor/stasis.png (grey) and empty_hand.png (colour, the plan's reference), both at 2x density and pixel for pixel the same figure. The grey reference is `python -I tools/art/pad_reference.py assets/sprites/world/story/mentor/stasis.png tools/art/sources/guardians/mentor_grey_ref.png 256x192 --at=bottom --axis=34`, the colour one the same command on empty_hand.png (mentor_colour_ref.png): still column 34 on the flip axis; PixelLab animates the 2x still and the cut halves it (systems/art-pipeline, Guardians). Round 2 (2026-10-30, the user on the first strips: 'No geral ta ok, mas falta ser mais animado'): PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_mentor_walk -Name guardian_mentor_walk_v2 -Out tools/art/sources/guardians -Action "<the action above>"`; the returned frames kept in tools/art/sources/guardians/guardian_mentor_walk_v2/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_mentor_walk_v2 guardian_mentor_walk_v2 assets/sprites/world/story/mentor/stasis.png assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_walk.png --write=1 --floor=191 --drop=45 --keep=0-7` then `python -I tools/art/despeckle.py assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_walk.png 128 --min=3`: every pixel snapped to the stasis still's 8 greys, feet on art row 95. Returned frames 0-7, a closed loop: long strides with the legs out of the robe on frames 3-5, the robe swinging. The first round's strip came from guardian_mentor_walk/ and is superseded. No pack art was shown to any generator; every reference is our own still or our own strip of this guardian.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, flute, text, ground, scenery

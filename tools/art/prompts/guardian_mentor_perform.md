---
id: guardian_mentor_perform
command: animate3
target: res://assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_perform.png
size: 128x96
frames: 8
keep: 0-4,3-1
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/mentor_play_colour_2x.png
action: playing an absent flute: the tall old hooded man in a long robe of moss and lichen keeps his raised empty hand at his mouth, his fingers moving as if fingering a flute that is not there, swaying softly; his hand stays empty; seen from the side facing left the whole time
source: pixellab
---
The performance, 1.6 s at 0.2 s a frame, a loop, in his own colours. The mentor as a guardian, the final battle (GRD-06, `architecture/grd-06-final-battle` section 6): the guardian of the crack and the most corrupted of all (design 02 section 5), a tall old man in a long hooded robe of lichen and moss flecked with snow, a pale mask-like face under the hood, the robe trailing behind him; in the fight he is grey and stiff, in the stasis still's eight flat greys, and he has no flute (he gave it to Ivo). Seen from the side facing west, the robe's middle under the head on the flip axis, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (128x96), shown at Sprite2D scale 2; the body is 43x60 art px, the story still's 86x120 game px. The stills are our own: assets/sprites/world/story/mentor/stasis.png (grey) and empty_hand.png (colour, the plan's reference), both at 2x density and pixel for pixel the same figure. The grey reference is `python -I tools/art/pad_reference.py assets/sprites/world/story/mentor/stasis.png tools/art/sources/guardians/mentor_grey_ref.png 256x192 --at=bottom --axis=34`, the colour one the same command on empty_hand.png (mentor_colour_ref.png): still column 34 on the flip axis; PixelLab animates the 2x still and the cut halves it (systems/art-pipeline, Guardians). The empty hand at the mouth (user, 2026-10-30: 'Mão vazia erguida (Recommended)'). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_mentor_perform -Name guardian_mentor_perform -Out tools/art/sources/guardians`; the returned frames kept in tools/art/sources/guardians/guardian_mentor_perform/) from the playing still tools/art/sources/guardians/mentor_play_colour_2x.png (see `guardian_mentor_perform_end`), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_mentor_perform guardian_mentor_perform assets/sprites/world/story/mentor/empty_hand.png assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_perform.png --write=1 --floor=191 --drop=45 --keep=0-4,3-1` then `python -I tools/art/despeckle.py assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_perform.png 128 --min=3`: every pixel snapped to the colour still's 12 colours, feet on art row 95. A ping-pong loop of returned frames 0-4: the hand drifts from the mouth to just before the face and back, the fingers moving; returned frame 8 did not come back to the mouth, so the return run closes the loop. No flute was drawn. No pack art was shown to any generator; every reference is our own still or our own strip of this guardian.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, flute, text, ground, scenery

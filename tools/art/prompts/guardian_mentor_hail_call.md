---
id: guardian_mentor_hail_call
command: animate3
target: res://assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_hail_call.png
size: 128x96
frames: 8
keep: 2-9
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/mentor_grey_ref.png
action: summon: the tall old hooded man raises one arm straight up above his hood with the open hand to the sky, holds it high and still, then jabs the hand upward three times, then lowers the arm to his side; side view facing left the whole time
source: pixellab
---
The hail (`mentor_icicle_fall.tres`, `mentor_icicle_again.tres`; clip_index 4, windup_index 3, recovery_index 2): wind-up 0.55 s (frames 0-2: the arm goes straight up; it must differ from the slam's arm raised forward), strike 1.1 s with three icicles at 0.15, 0.55, 0.95 (frames 3-6: one upward jab per icicle; the icicles are the Frost's drawn spawns), recovery 0.6 s (frame 7). The mentor as a guardian (GRD-06, `architecture/grd-06-final-battle`): a tall old man in a long hooded robe of lichen and moss flecked with snow, a pale mask-like face under the hood, the robe trailing behind him; in the fight he is grey and stiff, in the stasis still's eight flat greys, with no flute. Seen from the side facing west, the robe's middle under the head on the flip axis, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (128x96), shown at Sprite2D scale 2; the reference is our own 2x grey still padded to the frame (guardian_mentor_attack_1 says how it was made); PixelLab animates the 2x still and the cut halves it. One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The mentor's fight); `keep:` is set after the look. A 256x192 reference allows at most 10 frames (systems/art-pipeline). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_mentor_hail_call -Name guardian_mentor_hail_call_g18 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_mentor_hail_call_g18 guardian_mentor_hail_call_g18 assets/sprites/world/story/mentor/stasis.png assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_hail_call.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=3`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, flute, text, ground, scenery, icicles, ice

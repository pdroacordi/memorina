---
id: guardian_mentor_pounce
command: animate3
target: res://assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_pounce.png
size: 128x96
frames: 8
keep: 2-9
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/mentor_grey_ref.png
action: pounce: the tall old hooded man seen strictly in profile facing left crouches low with knees bent, then leaps forward to the left in a long low flat arc leaning forward like a diving bird, both arms reaching ahead of his hood, his robe streaming out behind him to the right, then lands crouched on both feet with one hand on the ground ahead of him, then rises; profile view facing left in every frame, his chest never turns toward the viewer
source: pixellab
---
The pounce (`mentor_pounce.tres`, `mentor_pounce_again.tres`; clip_index 5, windup_index 5, recovery_index 4; stage 2): wind-up 0.45 s (frames 0-1: the gather, rising), strike 0.9 s (frame 2 the spring at 0.1, frames 3-5 the arc to 0.7 while `LeapMotion` carries it 110 px up, frame 6 the landing with the box live 0.62-0.85), recovery 0.45 s (frame 7). Feet on the floor row on every frame: the arc is the guardian's own motion. Today it uses the lucidity leap's strip. The mentor as a guardian (GRD-06, `architecture/grd-06-final-battle`): a tall old man in a long hooded robe of lichen and moss flecked with snow, a pale mask-like face under the hood, the robe trailing behind him; in the fight he is grey and stiff, in the stasis still's eight flat greys, with no flute. Seen from the side facing west, the robe's middle under the head on the flip axis, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (128x96), shown at Sprite2D scale 2; the reference is our own 2x grey still padded to the frame (guardian_mentor_attack_1 says how it was made); PixelLab animates the 2x still and the cut halves it. One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The mentor's fight); `keep:` is set after the look. A 256x192 reference allows at most 10 frames (systems/art-pipeline). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_mentor_pounce -Name guardian_mentor_pounce_g18r2 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_mentor_pounce_g18r2 guardian_mentor_pounce_g18r2 assets/sprites/world/story/mentor/stasis.png assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_pounce.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=3`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, flute, text, ground, scenery, facing the viewer, arms spread sideways, legs apart

---
id: guardian_mentor_seed_cast
command: animate3
target: res://assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_seed_cast.png
size: 128x96
frames: 8
keep: 0-2,6-10
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/mentor_grey_ref.png
action: throw: the tall old hooded man reaches down to the ground in front of him with one hand, then swings the arm up and forward and points the open hand ahead at head height, holds it, then lowers the arm to his side; side view facing left the whole time
source: pixellab
---
The seeds (`mentor_spring.tres`, clip_index 6, windup_index 6, recovery_index 5; stage 2): wind-up 0.5 s (frames 0-2: the reach down to the floor and the gather, standing, not kneeling), strike 0.5 s with three pods thrown at 0.1 (frames 3-5: the sowing throw; the pods are Bloom's drawn spawns, so the hand stays empty), recovery 0.4 s (frames 6-7). The mentor as a guardian (GRD-06, `architecture/grd-06-final-battle`): a tall old man in a long hooded robe of lichen and moss flecked with snow, a pale mask-like face under the hood, the robe trailing behind him; in the fight he is grey and stiff, in the stasis still's eight flat greys, with no flute. Seen from the side facing west, the robe's middle under the head on the flip axis, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (128x96), shown at Sprite2D scale 2; the reference is our own 2x grey still padded to the frame (guardian_mentor_attack_1 says how it was made); PixelLab animates the 2x still and the cut halves it. One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The mentor's fight); `keep:` is set after the look. A 256x192 reference allows at most 10 frames (systems/art-pipeline). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_mentor_seed_cast -Name guardian_mentor_seed_cast_g18r3 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_mentor_seed_cast_g18r3 guardian_mentor_seed_cast_g18r3 assets/sprites/world/story/mentor/stasis.png assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_seed_cast.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=3`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, flute, text, ground, scenery, seeds, thrown objects, staff, stick, cane, weapon

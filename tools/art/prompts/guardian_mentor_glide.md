---
id: guardian_mentor_glide
command: animate3
target: res://assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_glide.png
size: 128x96
frames: 8
keep: 1-4,6-6,8-10
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/mentor_grey_ref.png
action: gliding sweep: the tall old hooded man drops low with one arm swept far back behind him, then glides forward on the spot with his robe streaming behind and his body leaning far forward, sweeping the open hand low along the floor ahead of him, then straightens up; side view facing left the whole time
source: pixellab
---
The glide (`mentor_glide_sweep.tres`, clip_index 3, windup_index 1, recovery_index 0): wind-up 0.45 s (frames 0-1: the arm low behind; it must differ from the sweep's hand drawn back), strike 0.5 s with `DashMotion` 560 px/s and the sweep's box live 0.2-0.4 (frames 2-6: the leaning glide, the robe streaming back, the hand low ahead, 20-64 px ahead of the axis, under 48 px over the floor), recovery 0.55 s (frame 7). Feet on the floor row on every frame: the slide is the guardian's own motion. Today it replays the sweep's frames. The mentor as a guardian (GRD-06, `architecture/grd-06-final-battle`): a tall old man in a long hooded robe of lichen and moss flecked with snow, a pale mask-like face under the hood, the robe trailing behind him; in the fight he is grey and stiff, in the stasis still's eight flat greys, with no flute. Seen from the side facing west, the robe's middle under the head on the flip axis, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (128x96), shown at Sprite2D scale 2; the reference is our own 2x grey still padded to the frame (guardian_mentor_attack_1 says how it was made); PixelLab animates the 2x still and the cut halves it. One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The mentor's fight); `keep:` is set after the look. A 256x192 reference allows at most 10 frames (systems/art-pipeline). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_mentor_glide -Name guardian_mentor_glide_g18 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_mentor_glide_g18 guardian_mentor_glide_g18 assets/sprites/world/story/mentor/stasis.png assets/sprites/characters/guardians/mentor_guardian/mentor_guardian_glide.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=3`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, flute, text, ground, scenery

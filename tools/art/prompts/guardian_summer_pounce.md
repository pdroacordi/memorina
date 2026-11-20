---
id: guardian_summer_pounce
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_pounce.png
size: 192x96
frames: 10
keep: 1-10
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: pounce: the stone lion crouches low on all four legs with its haunches raised, springs forward and up with its front legs stretched ahead and its body long, then comes down front paws first and lands heavily in a crouch with all four paws on the ground, then rises to stand; side view facing left the whole time
source: pixellab
---
The pounce slam (`summer_pounce_slam.tres`, clip_index 6, windup_index 7, recovery_index 6; stage 1): wind-up 0.5 s (frames 0-1: the crouch), strike 1.1 s (frame 2 the spring at 0.25, frames 3-5 the stretched flight to 0.85 while `LeapMotion` carries it 96 px up, frame 6 the landing with the box live 0.75-1.0 over 66 px each side), recovery 0.6 s (frames 7-9). Feet on the floor row on every frame: the arc is the guardian's own motion. Today it is cut from the leap strip. The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (192x96), shown at Sprite2D scale 2; the flip axis (x 96) is the torso's centre; the reference is our own still padded to the frame (guardian_summer_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Sun Guardian's fight); `keep:` is set after the look. The wind-up's first frame must not read as the idle stance (the GRD-16 feel pass). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_pounce -Name guardian_summer_pounce_g18 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_pounce_g18 guardian_summer_pounce_g18 tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_pounce.png --scale=1 --keep=<keep> --floor=95 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, particles

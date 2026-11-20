---
id: guardian_summer_ember_spit
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_ember_spit.png
size: 192x96
frames: 8
keep: 1-8
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: spit: the stone lion rears its head up and far back with its chest swelling and its jaws shut, the neck stretched high, then whips its head forward and down low in front of its front paws with its jaws gaping wide open as if spitting, holds the gaping jaws low, then lifts its head back to standing; side view facing left the whole time, a big clear head movement from high to low
source: pixellab
---
The ember spit (`summer_ember_spit.tres`, clip_index 4, windup_index 5, recovery_index 4): wind-up 0.45 s (frames 0-2: the head jerked back, which today borrows the hurt strip and reads as a flinch), strike 0.5 s with three embers from the mouth at 0.1, 0.2, 0.3 (frames 3-5: the jaws thrust forward and open; the embers are spawns, so nothing is drawn leaving the mouth), recovery 0.4 s (frames 6-7). The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (192x96), shown at Sprite2D scale 2; the flip axis (x 96) is the torso's centre; the reference is our own still padded to the frame (guardian_summer_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Sun Guardian's fight); `keep:` is set after the look. The wind-up's first frame must not read as the idle stance (the GRD-16 feel pass). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_ember_spit -Name guardian_summer_ember_spit_g18r2 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_ember_spit_g18r2 guardian_summer_ember_spit_g18r2 tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_ember_spit.png --scale=1 --keep=<keep> --floor=95 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, fire, embers, particles

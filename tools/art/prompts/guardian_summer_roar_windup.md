---
id: guardian_summer_roar_windup
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_roar_windup.png
size: 192x96
frames: 3
keep: 1-3
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: roar wind-up: the stone lion presses its front half down low with its chest almost touching the ground and its haunches high, lowers its head under its huge sun-ray mane, then lifts the head up with its jaws gaping wide open and the mane bristling straight out, drawing breath before a roar; side view facing left the whole time, a big clear change from standing
source: pixellab
---
The roar's wind-up (`summer_roar.tres`, windup_index 4, slot `windup_5`): 0.6 s telegraph (frames 0-3, the last held until the roar's first strike frame); asked for new on the user's answer "new" (2026-11-20). It must differ from the sun shafts' rise (which goes up on the hind legs): here the chest sinks and the mane bristles. The roar strike stays the GRD-04 `attack_3` strip. The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (192x96), shown at Sprite2D scale 2; the flip axis (x 96) is the torso's centre; the reference is our own still padded to the frame (guardian_summer_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Sun Guardian's fight); `keep:` is set after the look. The wind-up's first frame must not read as the idle stance (the GRD-16 feel pass). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_roar_windup -Name guardian_summer_roar_windup_g18r2 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_roar_windup_g18r2 guardian_summer_roar_windup_g18r2 tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_roar_windup.png --scale=1 --keep=<keep> --floor=95 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, particles, sound waves

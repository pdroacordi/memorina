---
id: guardian_summer_claw_other_paw
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_claw_other_paw.png
size: 192x96
frames: 10
keep: 1-10
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: second claw: the stone lion, its first paw just set down, lifts its other front paw high beside its mane with the claws spread, then rakes it down and forward low over the floor while it steps in, the leg stretched out in front of its head, then sets the paw down and stands on four legs; side view facing left the whole time
source: pixellab
---
The second claw (`summer_claw_again.tres`, link after the claw; windup_index 8, clip_index 7, recovery_index 7; slots `windup_9`, `attack_8`, `recover_8`, added for it on the user's answer "add", 2026-11-20): wind-up 0.3 s (frames 0-1: the other paw raised; it must differ from the claw's raised paw, which is the near one), strike 0.5 s with the box live 0.167-0.333 while `DashMotion` steps it in (frames 2-7: the rake, the paw low and 56-112 px ahead of the axis, under 48 px over the floor), recovery 0.4 s (frames 8-9). The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (192x96), shown at Sprite2D scale 2; the flip axis (x 96) is the torso's centre; the reference is our own still padded to the frame (guardian_summer_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Sun Guardian's fight); `keep:` is set after the look. The wind-up's first frame must not read as the idle stance (the GRD-16 feel pass). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_claw_other_paw -Name guardian_summer_claw_other_paw_g18 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_claw_other_paw_g18 guardian_summer_claw_other_paw_g18 tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_claw_other_paw.png --scale=1 --keep=<keep> --floor=95 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, particles

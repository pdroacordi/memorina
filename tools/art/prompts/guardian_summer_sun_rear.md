---
id: guardian_summer_sun_rear
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_sun_rear.png
size: 192x96
frames: 10
keep: 1-10
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: rearing call: the stone lion rises up onto its hind legs with its chest high, its sun-ray mane flaring wide and its head thrown back, holds the rear with its front paws lifted and swaying slightly, then drops back down onto four legs; its mane keeps the same ochre, orange and pale gold colours in every frame, never turning white; side view facing left the whole time
source: pixellab
---
The sun shafts (`summer_sun_shafts.tres`, clip_index 5, windup_index 6, recovery_index 5; stage 1): wind-up 0.5 s (frames 0-2: the rise; it must differ from the roar's crouch), strike 2.85 s held up (frames 3-7 looped while the four shafts light and burn; the shafts are spawns), recovery 0.5 s (frames 8-9: back onto four legs). Its pose is a sustained call, not the roar's rear and slam. The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (192x96), shown at Sprite2D scale 2; the flip axis (x 96) is the torso's centre; the reference is our own still padded to the frame (guardian_summer_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Sun Guardian's fight); `keep:` is set after the look. The wind-up's first frame must not read as the idle stance (the GRD-16 feel pass). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_sun_rear -Name guardian_summer_sun_rear_g18r2 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_sun_rear_g18r2 guardian_summer_sun_rear_g18r2 tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_sun_rear.png --scale=1 --keep=<keep> --floor=95 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, light beams, particles, white mane, bleached colours, light

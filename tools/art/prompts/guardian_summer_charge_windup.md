---
id: guardian_summer_charge_windup
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_charge_windup.png
size: 192x96
frames: 4
keep: 2-2,4-4,6-6,8-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: charge wind-up: the stone lion drops low on bent legs, draws its haunches back and lowers its head under its sun-ray mane, one front paw scraping the ground backward, the whole body coiled to run forward; side view facing left the whole time
source: pixellab
---
The charge's wind-up (`summer_charge.tres`, windup_index 2, slot `windup_3`): 0.6 s telegraph, the body held still while it coils (frames 0-3, the last held until the charge's first strike frame); asked for new on the user's answer "new" (2026-11-20). It must differ from the pounce's crouch (which springs up) and the bite's coiled head: here the head is down and the paw scrapes. The charge strike stays the GRD-04 `attack_2` strip. The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (192x96), shown at Sprite2D scale 2; the flip axis (x 96) is the torso's centre; the reference is our own still padded to the frame (guardian_summer_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Sun Guardian's fight); `keep:` is set after the look. The wind-up's first frame must not read as the idle stance (the GRD-16 feel pass). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_charge_windup -Name guardian_summer_charge_windup_g18 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_charge_windup_g18 guardian_summer_charge_windup_g18 tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_charge_windup.png --scale=1 --keep=<keep> --floor=95 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, particles, dust

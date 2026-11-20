---
id: guardian_summer_bite
command: animate3
target: res://assets/sprites/characters/guardians/summer_guardian/summer_guardian_bite.png
size: 192x96
frames: 8
keep: 1-6,9-10
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/sun_lion_ref.png
action: bite lunge: the stone lion lowers its head and coils back on its haunches, then lunges a short step forward with its jaws wide open at chest height and snaps them shut, then pulls its head back and stands; side view facing left the whole time
source: pixellab
---
The bite lunge (`summer_bite_lunge.tres`, a link after the second claw; clip_index 3, windup_index 1, recovery_index 1): wind-up 0.35 s (frames 0-1: head low, coiled), strike 0.45 s with a 40 px step 0.05-0.2 and the box live 0.05-0.25 (frames 2-5: the open jaws 60-124 px ahead of the axis, 24-80 px over the floor), recovery 0.5 s (frames 6-7). The summer guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), the sun-lion: a heavy, long, low lion of dark porous volcanic stone (charcoal and warm dark brown) with flat orange in its pores, a big mane of flat pointed sun rays in ochre, orange and pale gold around its head, a thin stone tail ending in a tuft of sun rays; a quadruped seen from the side facing west, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px (192x96), shown at Sprite2D scale 2; the flip axis (x 96) is the torso's centre; the reference is our own still padded to the frame (guardian_summer_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Sun Guardian's fight); `keep:` is set after the look. The wind-up's first frame must not read as the idle stance (the GRD-16 feel pass). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_summer_bite -Name guardian_summer_bite_g18 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_summer_bite_g18 guardian_summer_bite_g18 tools/art/sources/guardians/sun_lion_still.png assets/sprites/characters/guardians/summer_guardian/summer_guardian_bite.png --scale=1 --keep=<keep> --floor=95 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, particles

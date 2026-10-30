---
id: guardian_frost_lucid_enter
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_lucid_enter.png
size: 192x128
frames: 4
keep: 2-2,5-5,7-7,8-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_idle_f0.png
action: coming to its senses: the ice golem shakes its head hard as if shaking off a daze, shudders once, then straightens up tall and stands still, calm; its body stays in place
source: pixellab
---
The madness leaving, 0.6 s at 0.15 s a frame, one-shot (GRD-08, `architecture/guardian-performance-and-talks`; must stay under `lucidity_delay - leap_crouch`): shaking off, straightening; the last frame is frame 0 of `frost_guardian_lucid.png`, so the clip settles into `lucid` without a jump. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The reference is tools/art/sources/guardians/frost_idle_f0.png (frost_guardian_idle.png frame 0, the strip's frame 0 at 1x). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_lucid_enter -Name guardian_frost_lucid_enter -Out tools/art/sources/guardians`; returned frames in tools/art/sources/guardians/guardian_frost_lucid_enter/), cut whole by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_lucid_enter guardian_frost_lucid_enter tools/art/sources/guardians/frost_still.png tools/art/sources/guardians/guardian_frost_lucid_enter_cut.png --scale=1 --floor=127 --centre=43-78 --keep=0-8` and composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/frost_guardian/frost_guardian_lucid_enter.png 192 tools/art/sources/guardians/guardian_frost_lucid_enter_cut.png@2 tools/art/sources/guardians/guardian_frost_lucid_enter_cut.png@5 tools/art/sources/guardians/guardian_frost_lucid_enter_cut.png@7 tools/art/sources/guardians/frost_lucid_f0.png`: the head thrown back, straightening, upright, then frost_guardian_lucid.png frame 0 itself. `keep` names the returned frames; its last is replaced by that continuity frame. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery

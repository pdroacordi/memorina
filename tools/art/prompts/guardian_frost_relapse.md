---
id: guardian_frost_relapse
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_relapse.png
size: 192x128
frames: 5
keep: 1-1,3-4,2-2,8-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_lucid_f0.png
action: falling back into madness: the ice golem shudders violently, clutches itself and hunches over, falling back into a dazed, twitching stance; its body stays in place
source: pixellab
---
Falling back into madness, 0.75 s at 0.15 s a frame, one-shot (GRD-08; must stay under `relapse_time * FAILED_RELAPSE_SCALE`, 0.84 s): a shudder, hunching; the last frame is frame 0 of `frost_guardian_idle.png`, so the clip settles into `idle` without a jump. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The reference is tools/art/sources/guardians/frost_lucid_f0.png (frost_guardian_lucid.png frame 0, the strip's frame 0 at 1x). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_relapse -Name guardian_frost_relapse -Out tools/art/sources/guardians`; returned frames in tools/art/sources/guardians/guardian_frost_relapse/), cut whole by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_relapse guardian_frost_relapse tools/art/sources/guardians/frost_still.png tools/art/sources/guardians/guardian_frost_relapse_cut.png --scale=1 --floor=127 --centre=43-78 --keep=0-8` and composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/frost_guardian/frost_guardian_relapse.png 192 tools/art/sources/guardians/guardian_frost_relapse_cut.png@1 tools/art/sources/guardians/guardian_frost_relapse_cut.png@3 tools/art/sources/guardians/guardian_frost_relapse_cut.png@4 tools/art/sources/guardians/guardian_frost_relapse_cut.png@2 tools/art/sources/guardians/frost_idle_f0.png --despeckle=2:40`: the shudder, the hunch, half up, then frost_guardian_idle.png frame 0 itself; --despeckle=2:40 clears the ice flecks PixelLab threw off the back on returned frame 4 (parts of 23-33 px; returned frames 5-8 burst into ice and are unused). `keep` names the returned frames; its last is replaced by that continuity frame. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery

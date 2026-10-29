---
id: guardian_frost_lucid
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_lucid.png
size: 192x128
frames: 6
keep: 0-3,2-1
generate: 6
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_ref.png
action: lucid: the ice golem trembles and shudders in place, dazed, swaying slightly, as if waking from a trance; it stays standing
source: pixellab
---
The lucid tremble between corrupted and lucid, 0.9 s at 0.15 s a frame; the shield does the colour (systems/guardians). The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row (today's pack sheets stand on row 109, so wiring moves the Sprite2D from y -92 to -128; the 18 rows freed above hold the raised fists). Sheets are 1 px per art px, shown at Sprite2D scale 2. The still is cut from our own Codex concept tools/art/sources/guardians/guardians_concept_codex.png (approved by the user 2026-10-29: "A, the tree-stag" and "A, the ice golem"; "Scale to today's"): `python -I tools/art/cut_creatures.py tools/art/sources/guardians/guardians_concept_codex.png tools/art/sources/guardians --names=-,bloom_cut,-,frost --pitch=4-12 --colors=16 --size=bloom_cut:h44,frost:h92` cut it at 60x92 art px, the height of today's Frost body (92 art px): frost_still.png. The reference is the still padded onto the 192x128 frame (`python -I tools/art/pad_reference.py tools/art/sources/guardians/frost_still.png tools/art/sources/guardians/frost_ref.png 192x128 --at=bottom`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_lucid -Name guardian_frost_lucid -Out tools/art/sources/guardians`; the returned frames kept in tools/art/sources/guardians/guardian_frost_lucid/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_lucid guardian_frost_lucid tools/art/sources/guardians/frost_still.png assets/sprites/characters/guardians/frost_guardian/frost_guardian_lucid.png --scale=1 --keep=0-3,2-1 --floor=127 --centre=43-78`: every pixel snapped to the still's colours, feet on the floor row, the torso centred on the flip axis. Kept as a ping-pong (0-3, 2-1): after frame 3 PixelLab drifts into a full profile. No pack art was shown to any generator; today's pack sheets were only measured (frame size, frame count, body bounds).
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery

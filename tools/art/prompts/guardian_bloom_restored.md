---
id: guardian_bloom_restored
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_restored.png
size: 128x96
frames: 4
keep: 0-3
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_ref_2x.png
action: restored: the tree-stag stands calm and at peace, breathing slowly, its head gently lowered, seen from the side facing left the whole time
source: pixellab
---
Restored: calm, at peace, 0.6 s at 0.15 s a frame. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The still is cut from our own Codex concept tools/art/sources/guardians/guardians_concept_codex.png (approved by the user 2026-10-29: "A, the tree-stag" and "A, the ice golem"; "Scale to today's"): `python -I tools/art/cut_creatures.py tools/art/sources/guardians/guardians_concept_codex.png tools/art/sources/guardians --names=-,bloom60_cut,-,- --pitch=4-12 --colors=16 --size=bloom60_cut:h60` cut it at 22x60 art px ("Redo it bigger", user, 2026-10-29: about 60 art px tall, towering over Ivo's 29 and filling its hurtbox; today's pack Bloom is 44 tall); PixelLab pixflux redrew the cut at art size with it as the init image (`tools/pixellab/pixellab.ps1 generate -Width 80 -Height 80 -NoBackground -Reference tools/art/sources/guardians/bloom60_init.png`, the cut padded by pad_reference.py; kept as bloom60_pixflux.png), cleaned by `python -I tools/art/clean_prop.py tools/art/sources/guardians/bloom60_pixflux.png tools/art/sources/guardians/bloom_still_2x.png --flat=16` and halved, nearest, to bloom_still.png (22x60). The reference is the 2x still padded onto a 2x frame (`python -I tools/art/pad_reference.py tools/art/sources/guardians/bloom_still_2x.png tools/art/sources/guardians/bloom_ref_2x.png 256x192 --at=bottom`), so PixelLab draws the slender stag at 2x and the cut halves it. The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_restored -Name guardian_bloom_restored_v60 -Out tools/art/sources/guardians`; the returned frames kept in tools/art/sources/guardians/guardian_bloom_restored_v60/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_restored_v60 guardian_bloom_restored_v60 tools/art/sources/guardians/bloom_palette.png assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_restored.png --write=1 --keep=0-3 --floor=191 --centre=80-140 --drop=45`: every pixel snapped to the still's colours less its near-white (bloom_palette.png, so --drop=45 clears the white trails and flashes PixelLab paints), feet on the floor row, the torso centred on the flip axis. --drop=45 clears white flecks PixelLab drew over the antlers. No pack art was shown to any generator; today's pack sheets were only measured (frame size, frame count, body bounds).
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery

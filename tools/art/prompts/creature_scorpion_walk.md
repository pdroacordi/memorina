---
id: creature_scorpion_walk
command: animate3
target: res://assets/sprites/characters/creatures/scorpion/scorpion_walk.png
size: 80x64
frames: 6
keep: 0-5
generate: 6
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/scorpion_ref.png
action: walk: the scorpion walks forward to the left, eight legs stepping in a loop, tail raised, body level
source: pixellab
---
A walk loop of a scorpion, a corrupted creature of the Summer Caldera (CORE-13), seen from the side facing west, feet on the frame bottom row, body centred. The still was cut from the Codex sheet tools/art/sources/creatures/corrupted_codex.png (approved by the user 2026-10-29 ("Approve")) by tools/art/cut_creatures.py at the board's size, shrank to mush, and was redrawn at its exact art size by PixelLab pixflux with that cut as the init image (`tools/pixellab/pixellab.ps1 generate -Width 32 -Height 32 -NoBackground -Reference tools/art/sources/creatures/pixellab/scorpion_init.png`; raw kept as tools/art/sources/creatures/pixellab/scorpion_px.png), cleaned by `python -I tools/art/clean_prop.py tools/art/sources/creatures/pixellab/scorpion_px.png tools/art/sources/creatures/scorpion_still_2x.png --flat=12`. The reference is the 2x still padded onto the 80x64 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/scorpion_still_2x.png tools/art/sources/creatures/scorpion_ref.png 80x64 --at=bottom`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/scorpion_ref.png -Frames 6 -Action "<action>" -Name scorpion_walk`; the returned frames kept in tools/art/sources/creatures/scorpion_walk/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/scorpion_walk scorpion_walk tools/art/sources/creatures/scorpion_still_2x.png assets/sprites/characters/creatures/scorpion/scorpion_walk.png --keep=0-5 --floor=63 --centre=0-64`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1).
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

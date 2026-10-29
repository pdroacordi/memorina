---
id: creature_scorpion_strike
command: animate3
target: res://assets/sprites/characters/creatures/scorpion/scorpion_strike.png
size: 80x64
frames: 4
keep: 1-4
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/scorpion_ref.png
action: the scorpion strikes its tail stinger forward over its head to the left and down into the ground, then holds
source: pixellab
---
The tail strike of a scorpion, a corrupted creature of the Summer Caldera (CORE-13), seen from the side facing west, feet on the frame bottom row, body centred. The still was cut from the Codex sheet tools/art/sources/creatures/corrupted_codex.png (approved by the user 2026-10-29 ("Approve")) by tools/art/cut_creatures.py at the board's size, shrank to mush, and was redrawn at its exact art size by PixelLab pixflux with that cut as the init image (`tools/pixellab/pixellab.ps1 generate -Width 32 -Height 32 -NoBackground -Reference tools/art/sources/creatures/pixellab/scorpion_init.png`; raw kept as tools/art/sources/creatures/pixellab/scorpion_px.png), cleaned by `python -I tools/art/clean_prop.py tools/art/sources/creatures/pixellab/scorpion_px.png tools/art/sources/creatures/scorpion_still_2x.png --flat=12`. The reference is the 2x still padded onto the 80x64 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/scorpion_still_2x.png tools/art/sources/creatures/scorpion_ref.png 80x64 --at=bottom`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/scorpion_ref.png -Frames 4 -Action "<action>" -Name scorpion_strike`; the returned frames kept in tools/art/sources/creatures/scorpion_strike/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/scorpion_strike scorpion_strike tools/art/sources/creatures/scorpion_still_2x.png assets/sprites/characters/creatures/scorpion/scorpion_strike.png --keep=1-4 --floor=63 --centre=0-64`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1). Flagged: best of three tries, kept from the first: the tail dips forward a little; the stinger never stabs past the head. The second and third tries painted an impact flash in the scorpion's own light colour, which --drop cannot clear.
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

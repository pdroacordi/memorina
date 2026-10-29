---
id: creature_snail_sing
command: animate3
target: res://assets/sprites/world/creatures/snail/snail_sing.png
size: 32x32
frames: 4
keep: 0-3
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/snail_ref.png
action: the snail sings: it stretches its head up, opens its mouth and sways its eye stalks to the rhythm
source: pixellab
---
The sing loop, played while its three notes fill the balloon (design 02 §2) of the glass-shelled snail, the Redoma teacher, seen from the side facing west, feet on the frame bottom row, body centred. The still was cut from the Codex sheet tools/art/sources/creatures/teachers_codex.png (approved by the user 2026-10-29 ("Approve")) by tools/art/cut_creatures.py at the board's size, shrank to mush, and was redrawn at its exact art size by PixelLab pixflux with that cut as the init image (`tools/pixellab/pixellab.ps1 generate -Width 32 -Height 32 -NoBackground -Reference tools/art/sources/creatures/pixellab/snail_init.png`; raw kept as tools/art/sources/creatures/pixellab/snail_px.png), cleaned by `python -I tools/art/clean_prop.py tools/art/sources/creatures/pixellab/snail_px.png tools/art/sources/creatures/snail_still_2x.png --flat=12`. The reference is the 2x still padded onto the 32x32 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/snail_still_2x.png tools/art/sources/creatures/snail_ref.png 32x32 --at=bottom`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/snail_ref.png -Frames 4 -Action "<action>" -Name snail_sing`; the returned frames kept in tools/art/sources/creatures/snail_sing/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/snail_sing snail_sing tools/art/sources/creatures/snail_still_2x.png assets/sprites/world/creatures/snail/snail_sing.png --keep=0-3 --floor=31 --centre=0-32`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1).
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

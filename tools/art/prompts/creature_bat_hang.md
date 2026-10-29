---
id: creature_bat_hang
command: animate3
target: res://assets/sprites/characters/creatures/bat/bat_hang.png
size: 64x64
frames: 2
keep: 0-1
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/bat_ref.png
action: idle: the bat hangs upside down asleep, wings wrapped, swaying very slightly; its body stays still
source: pixellab
---
A hanging loop of an icicle bat, a corrupted creature of the Frozen Lake (CORE-13), seen from the side facing west, hanging from the frame's top row, body centred. The still was cut from the Codex sheet tools/art/sources/creatures/corrupted_codex.png (approved by the user 2026-10-29 ("Approve")) by tools/art/cut_creatures.py at the board's size, shrank to mush, and was redrawn at its exact art size by PixelLab pixflux with that cut as the init image (`tools/pixellab/pixellab.ps1 generate -Width 32 -Height 32 -NoBackground -Reference tools/art/sources/creatures/pixellab/bat_init.png`; raw kept as tools/art/sources/creatures/pixellab/bat_px.png), cleaned by `python -I tools/art/clean_prop.py tools/art/sources/creatures/pixellab/bat_px.png tools/art/sources/creatures/bat_still_2x.png --flat=12`. The reference is the 2x still padded onto the 64x64 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/bat_still_2x.png tools/art/sources/creatures/bat_ref.png 64x64 --at=top`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/bat_ref.png -Frames 4 -Action "<action>" -Name bat_hang`; the returned frames kept in tools/art/sources/creatures/bat_hang/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/bat_hang bat_hang tools/art/sources/creatures/bat_still_2x.png assets/sprites/characters/creatures/bat/bat_hang.png --keep=0-1 --centre=0-64`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1).
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

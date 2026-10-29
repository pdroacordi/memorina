---
id: creature_bat_fly
command: animate3
target: res://assets/sprites/characters/creatures/bat/bat_fly.png
size: 64x64
frames: 6
keep: 1-6
generate: 6
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/bat_open_ref.png
action: fly: the bat flies in place, flapping its wings up and down in a loop, body level
source: pixellab
---
A flying loop of an icicle bat, a corrupted creature of the Frozen Lake (CORE-13), seen from the side facing west, body centred. The still was cut from the Codex sheet tools/art/sources/creatures/corrupted_codex.png (approved by the user 2026-10-29 ("Approve")) by tools/art/cut_creatures.py at the board's size, shrank to mush, and was redrawn at its exact art size by PixelLab pixflux with that cut as the init image (`tools/pixellab/pixellab.ps1 generate -Width 32 -Height 32 -NoBackground -Reference tools/art/sources/creatures/pixellab/bat_init.png`; raw kept as tools/art/sources/creatures/pixellab/bat_px.png), cleaned by `python -I tools/art/clean_prop.py tools/art/sources/creatures/pixellab/bat_px.png tools/art/sources/creatures/bat_still_2x.png --flat=12`. The reference is tools/art/sources/creatures/bat_open_ref.png, the open-wing still: the last frame of bat_drop cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/bat_drop bat_drop tools/art/sources/creatures/bat_still_2x.png tools/art/sources/creatures/bat_open_ref.png --keep=4-4 --centre=0-64`; the wings are seen open from the front. The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/bat_open_ref.png -Frames 6 -Action "<action>" -Name bat_fly`; the returned frames kept in tools/art/sources/creatures/bat_fly/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/bat_fly bat_fly tools/art/sources/creatures/bat_still_2x.png assets/sprites/characters/creatures/bat/bat_fly.png --keep=1-6 --centre=0-64`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1).
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

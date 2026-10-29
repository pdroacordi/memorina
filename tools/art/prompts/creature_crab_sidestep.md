---
id: creature_crab_sidestep
command: animate3
target: res://assets/sprites/characters/creatures/crab/crab_sidestep.png
size: 64x48
frames: 6
keep: 0-5
generate: 6
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/crab_ref.png
action: the crab scuttles sideways to the left, legs stepping quickly in a loop, shell level
source: pixellab
---
A sidestep loop of a crab, a corrupted creature of Frost Edge (CORE-13), seen from the side facing west, feet on the frame bottom row, body centred. The still was cut from the Codex sheet tools/art/sources/creatures/corrupted_codex.png (approved by the user 2026-10-29 ("Approve")) by tools/art/cut_creatures.py at the board's size, shrank to mush, and was redrawn at its exact art size by PixelLab pixflux with that cut as the init image (`tools/pixellab/pixellab.ps1 generate -Width 32 -Height 32 -NoBackground -Reference tools/art/sources/creatures/pixellab/crab_init.png`; raw kept as tools/art/sources/creatures/pixellab/crab_px.png), cleaned by `python -I tools/art/clean_prop.py tools/art/sources/creatures/pixellab/crab_px.png tools/art/sources/creatures/crab_still_2x.png --flat=12`. The reference is the 2x still padded onto the 64x48 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/crab_still_2x.png tools/art/sources/creatures/crab_ref.png 64x48 --at=bottom`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/crab_ref.png -Frames 6 -Action "<action>" -Name crab_sidestep`; the returned frames kept in tools/art/sources/creatures/crab_sidestep/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/crab_sidestep crab_sidestep tools/art/sources/creatures/crab_still_2x.png assets/sprites/characters/creatures/crab/crab_sidestep.png --keep=0-5 --floor=47 --centre=0-48`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1).
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

---
id: creature_hornet_recover
command: animate3
target: res://assets/sprites/characters/creatures/hornet/hornet_recover.png
size: 48x48
frames: 3
keep: 1-3
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/hornet_ref.png
action: the hornet stops after a dash, wobbles in the air and straightens back to hovering
source: pixellab
---
The recovery after a dash of a hornet, a corrupted creature of the Wind Orchards (CORE-13), seen from the side facing west, body centred in the frame. The still is cut from the Codex sheet tools/art/sources/creatures/corrupted_codex.png (approved by the user 2026-10-29 ("Approve")) by `python -I tools/art/cut_creatures.py tools/art/sources/creatures/corrupted_codex.png tools/art/sources/creatures --names=boar,-,-,spider,hornet,- --colors=14 --size=spider:w16,hornet:w16`: each drawn pixel read once on Codex's own grid, then reduced to the board's size (docs/design/drafts/creatures_board.md, Art workload). The reference is the 2x still padded onto the 48x48 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/hornet_still_2x.png tools/art/sources/creatures/hornet_ref.png 48x48 --at=middle`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/hornet_ref.png -Frames 4 -Action "<action>" -Name hornet_recover`; the returned frames kept in tools/art/sources/creatures/hornet_recover/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/hornet_recover hornet_recover tools/art/sources/creatures/hornet_still_2x.png assets/sprites/characters/creatures/hornet/hornet_recover.png --keep=1-3 --centre=0-48`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1).
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

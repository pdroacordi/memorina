---
id: creature_boar_hurt
command: animate3
target: res://assets/sprites/characters/creatures/boar/boar_hurt.png
size: 96x64
frames: 2
keep: 1-2
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/boar_ref.png
action: hurt: the wild boar recoils backwards from a hit, flinching, then recovers
source: pixellab
---
A hurt recoil of a wild boar, a corrupted creature of the Threshold (CORE-13), seen from the side facing west, feet on the frame bottom row, body centred. The still is cut from the Codex sheet tools/art/sources/creatures/corrupted_codex.png (approved by the user 2026-10-29 ("Approve")) by `python -I tools/art/cut_creatures.py tools/art/sources/creatures/corrupted_codex.png tools/art/sources/creatures --names=boar,-,-,spider,hornet,- --colors=14 --size=spider:w16,hornet:w16`: each drawn pixel read once on Codex's own grid, then reduced to the board's size (docs/design/drafts/creatures_board.md, Art workload). The reference is the 2x still padded onto the 96x64 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/boar_still_2x.png tools/art/sources/creatures/boar_ref.png 96x64 --at=bottom`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/boar_ref.png -Frames 4 -Action "<action>" -Name boar_hurt`; the returned frames kept in tools/art/sources/creatures/boar_hurt/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/boar_hurt boar_hurt tools/art/sources/creatures/boar_still_2x.png assets/sprites/characters/creatures/boar/boar_hurt.png --keep=1-2 --floor=63 --centre=0-64`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1).
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

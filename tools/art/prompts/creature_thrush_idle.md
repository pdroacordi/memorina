---
id: creature_thrush_idle
command: animate3
target: res://assets/sprites/world/creatures/thrush/thrush_idle.png
size: 32x32
frames: 4
keep: 0-3
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/thrush_ref.png
action: idle: the small bird stands in place, tilting its head and breathing; its body stays still
source: pixellab
---
An idle loop of the song thrush, the Chuva teacher, seen from the side facing west, feet on the frame bottom row, body centred. The still is cut from the Codex sheet tools/art/sources/creatures/teachers_codex.png (approved by the user 2026-10-29 ("Approve")) by `python -I tools/art/cut_creatures.py tools/art/sources/creatures/teachers_codex.png tools/art/sources/creatures --names=-,thrush,kestrel,lizard --colors=12 --size=thrush:w10,kestrel:h14,lizard:w18 --dot=thrush:2.1:2b211c,kestrel:3.1:2b211c`: each drawn pixel read once on Codex's own grid, then reduced to the board's size (docs/design/drafts/creatures_board.md, Art workload). The reference is the 2x still padded onto the 32x32 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/thrush_still_2x.png tools/art/sources/creatures/thrush_ref.png 32x32 --at=bottom`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/thrush_ref.png -Frames 4 -Action "<action>" -Name thrush_idle`; the returned frames kept in tools/art/sources/creatures/thrush_idle/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/thrush_idle thrush_idle tools/art/sources/creatures/thrush_still_2x.png assets/sprites/world/creatures/thrush/thrush_idle.png --keep=0-3 --floor=31 --centre=0-32 --ceiling=11`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1). PixelLab drew a white note over the head in frames 1-3 on both tries; --ceiling clears it.
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

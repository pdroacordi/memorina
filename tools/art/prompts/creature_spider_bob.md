---
id: creature_spider_bob
command: animate3
target: res://assets/sprites/characters/creatures/spider/spider_bob.png
size: 48x48
frames: 4
keep: 1-4
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/creatures/spider_ref.png
action: the spider bobs up and down on its legs, rising and sinking, in place
source: pixellab
---
A bob on its thread of a spider, a corrupted creature of the Spring Woods (CORE-13), seen from the side facing west, feet on the frame bottom row, body centred. The still is cut from the Codex sheet tools/art/sources/creatures/corrupted_codex.png (approved by the user 2026-10-29 ("Approve")) by `python -I tools/art/cut_creatures.py tools/art/sources/creatures/corrupted_codex.png tools/art/sources/creatures --names=boar,-,-,spider,hornet,- --colors=14 --size=spider:w16,hornet:w16`: each drawn pixel read once on Codex's own grid, then reduced to the board's size (docs/design/drafts/creatures_board.md, Art workload). The reference is the 2x still padded onto the 48x48 frame (`python -I tools/art/pad_reference.py tools/art/sources/creatures/spider_still_2x.png tools/art/sources/creatures/spider_ref.png 48x48 --at=bottom`). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/creatures/spider_ref.png -Frames 4 -Action "<action>" -Name spider_bob`; the returned frames kept in tools/art/sources/creatures/spider_bob/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/creatures/spider_bob spider_bob tools/art/sources/creatures/spider_still_2x.png assets/sprites/characters/creatures/spider/spider_bob.png --keep=1-4 --centre=0-48`: each 2x2 block to its most common colour, every pixel snapped to the still's colours. No death or spawn clip: the corruption shader dissolves the creature (creatures board, Part 1).
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery

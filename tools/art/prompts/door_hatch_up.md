---
id: door_hatch_up
command: generate
target: res://assets/sprites/world/props/door/door_hatch_up.png
size: 48x68
frames: 2
view: side
source: codex
---
A wooden ladder 1 unit wide and 2 tall reaching up to a closed square trapdoor in the ceiling; sealed, the trapdoor bound by an iron chain and padlock. In lighthouse_interior (look `hatch_up`), under a ceiling 64 px above the landing. Two frames side by side, open then sealed, bottom-aligned. No outline, matching the facades and tools/art/sources/door_codex.png (the only references, our own art). Cut by `python -I tools/art/cut_facades.py doorways tools/art/sources/doorways_codex.png <dir> door_passage:48,door_hatch_up:24,door_hatch_down:24`, 2x density. Approved in the running game: "Approve (Recommended)" (user, 2026-10-10), after "The cistern one is the only one that still looks kind of weird".
Negative: outlines, black contour, perspective, glow, light in the opening, text, people

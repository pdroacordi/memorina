---
id: door_stairwell
command: generate
target: res://assets/sprites/world/props/door/door_stairwell.png
size: 96x88
frames: 2
view: side
source: codex
---
A stairwell going down through a grey stone floor, side view: worn steps descending into darkness between two low kerb blocks; sealed, an iron grate across the opening. The floor line is 21 px below the top; the rest sinks into the floor (`Door.SINKS`). In caldera_cistern's chamber (look `stairwell`), whose ceiling is the Redoma slab and cannot rise for an arch. Two frames side by side, open then sealed, bottom-aligned. No outline, matching the facades and tools/art/sources/door_codex.png (the only references, our own art). Cut by `python -I tools/art/cut_facades.py doorways tools/art/sources/stairwell_codex.png <dir> door_stairwell:0 --side --opening=32 --keep-x=19:67 --colors=9` (open left, sealed right; scaled so the opening is 32 px wide, cropped to the kerbs), 2x density. Approved in the running game: "Approve (Recommended)" (user, 2026-10-10), after "The cistern one is the only one that still looks kind of weird".
Negative: outlines, black contour, perspective, glow, light in the opening, text, people

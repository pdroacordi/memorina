---
id: door_passage
command: generate
target: res://assets/sprites/world/props/door/door_passage.png
size: 96x102
frames: 2
view: side
source: codex
---
A doorway cut in the grey masonry of an old underground cistern: a round arch of big worn mossy blocks framing a dark opening with stone steps going down; sealed, a rusty iron grate. In caldera_cistern_bottom (look `passage`). Two frames side by side, open then sealed, bottom-aligned. No outline, matching the facades and tools/art/sources/door_codex.png (the only references, our own art). Cut by `python -I tools/art/cut_facades.py doorways tools/art/sources/doorways_codex.png <dir> door_passage:48,door_hatch_up:24,door_hatch_down:24` (3x2 sheet, open on top, sealed below; each column scaled to its open piece's art width), 2x density. Approved in the running game: "Approve (Recommended)" (user, 2026-10-10), after "The cistern one is the only one that still looks kind of weird".
Negative: outlines, black contour, perspective, glow, light in the opening, text, people

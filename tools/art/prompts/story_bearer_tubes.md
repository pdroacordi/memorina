---
id: story_bearer_tubes
command: generate
target: res://assets/sprites/story/bearers/bearer_tubes.png
size: 72x40
frames: 4
view: side
no_background: true
source: codex
---
STORY-04 notebook pages: the four guardian tubes, one drawing per Memories page ("O tubo e uma frase do Ivo (Recommended)", user, 2026-11-13; plan `docs/knowledge/architecture/story-04-bearer-fragments.md`). Frames in the draft's order: bloom (the living stem), frost (the petrified branch), autumn (the hollow bone), summer (the pierced stone). Each frame is 72x40 notebook px, 1 px per px of the notebook's 320x180 `Art` root (shown at scale 2, as the guardian portraits are), transparent, the tube lying horizontally and centred; it fits the 81 px wide page text rect above the title and Ivo's line (`systems/notebook`: page 81x106). Colour, in the tube's own material, no outlines, about 8 colours each.
Made by Codex image generation (codex-consult image mode, 2026-11-13; our own guardian stills `tools/art/sources/story/bearers/guardians_ref.png` the only reference), one row of four tubes on magenta kept as `tools/art/sources/story/bearers/tubes_codex.png`, prompt `tools/art/sources/story/bearers/tubes_prompt.txt`. Cut, one tube per box: `python -I tools/art/cut_engraving.py tube tools/art/sources/story/bearers/tubes_codex.png <out> --box=<the tube's quarter> --width=72 --height=40 --colors=8`, then the four laid side by side (boxes and the join in `tools/art/sources/story/bearers/tubes_cut.txt`).
Negative: outlines, black contour, hands, people, text, scenery, floor, shadow

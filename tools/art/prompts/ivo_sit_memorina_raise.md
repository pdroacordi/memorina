---
id: ivo_sit_memorina_raise
command: animate3
target: res://assets/sprites/characters/ivo/ivo_sit_memorina_raise.png
size: 128x128
frames: 5
view: side
direction: east
reference: res://tools/art/sources/story/ivo_sit_memorina_v2_2x.png
action: seated on a low bench that is not drawn, he lowers the small pan flute from his lips and rests it in his lap, his hands coming down onto his knees, ending seated at rest; he stays seated, boots flat on the ground; always in right-facing profile
keep: 1-3,5-6
generate: 6
source: pixellab
---
Ivo seated on the flat stone lowering the Memorina: played forward it is the lower (once, after `ivo_sit_memorina`), backward the raise (once, before it), as `ivo_memorina_lower` serves the standing draw (STORY-07, `architecture/story-07-epilogue` §Art 1). Rejected v1 (not kept; its strips and frames are not in the repo): "a proporção está errada" and "refazer alba e tbm o ivo nessa sentado, o cara tá esquisitão" (user, 2026-11-16).

Targets: 128x128 frames at the 2x density, feet on row 95; its first kept frame is the playing still (`ivo_sit_memorina`), its last lands on `ivo_sit.png` frame 0 (22 art px, hands on the knees, legs' centroid within 1 art px). Palette: his own plus the flute's.

The clip: PixelLab animate-with-text-v3 from the approved v2 still (tools/art/sources/story/ivo_sit_memorina_v2_2x.png; "Aprovar os dois", user, 2026-11-16; frames in tools/art/sources/story/ivo_sit_memorina_raise/; 1 holds the flute at his lips, 2 lowers it, 3 rests it in his lap, 5 has his hands on his knees), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_sit_memorina_raise ivo_sit_memorina_raise_v2 tools/art/sources/story/ivo_sit_memorina_v2_2x.png <out> --keep=1-3,5-5 --floor=95`; its frame 5 still leans back from the rest (112 px of 1144 differ), so the strip closes on `ivo_sit.png` frame 0 itself, in the place of returned frame 6 (the `keep` lists it there): `python -I tools/art/compose_strip.py <out> 128 <cut>@0 <cut>@1 <cut>@2 <cut>@3 assets/sprites/characters/ivo/ivo_sit.png@0` (5 frames). Clip approved: "Aprovar" (user, 2026-11-16).

Negative: outlines, black contour, front view, facing left, glow, music notes, text, ground, scenery, a drawn seat

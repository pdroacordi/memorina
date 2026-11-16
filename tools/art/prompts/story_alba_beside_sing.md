---
id: story_alba_beside_sing
command: animate3
target: res://assets/sprites/world/story/alba/beside_sing.png
size: 64x64
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/alba_beside_v2_2x.png
action: seated upright on a low stone that is not drawn, singing softly: her mouth opens and closes gently with the song, her head rises a little and sways, her chest rises with each breath, hands resting in her lap; she stays seated, feet still, always in right-facing profile
keep: 0-2,5-7
generate: 8
source: pixellab
---
Alba singing while seated beside Ivo on the flat stone, a gentle loop for the duet (STORY-07, `architecture/story-07-epilogue` §Art 2). "Sim, na pedra (Recommended)" (user, 2026-11-16): her old `sit_sing` is the crouch on the ground, so on the stone she sings from this pose. Rejected v1 (not kept; its strips and frames are not in the repo): "a proporção está errada" and "refazer alba e tbm o ivo nessa sentado, o cara tá esquisitão" (user, 2026-11-16).

Targets: the same frame, seat and scale as `story_alba_beside` (64x64 at the 2x density, feet on row 61, seated 10x20 art px, lap 9 art px over her feet, no lift). Palette: her own.

The clip: PixelLab animate-with-text-v3 from the approved v2 still (tools/art/sources/story/alba_beside_v2_2x.png; "Aprovar os dois", user, 2026-11-16; frames in tools/art/sources/story/alba_beside_sing/; 3 and 4 move her feet, so 0-2 and 5-7 are kept), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/alba_beside_sing alba_beside_sing_v2 tools/art/sources/story/alba_beside_v2_2x.png <out> --keep=0-2,5-7 --floor=61`. Her mouth is drawn by hand in the cut strip, in her own palette, since PixelLab draws it too faint to read: "Aprovar; boca à mão (Recommended)" (user, 2026-11-16). Sheet frame 0 is closed, a lip pixel (175,79,33) at art (17,16); frames 1-5 are open, a dark (111,55,27) mouth two art px wide on the row under her eye at the front of her face (frames 1-3 at art (16,15) and (17,15), frame 4 at (16,14) and (17,14), frame 5 at (16,16) and (17,16)), and frame 3, the peak, also at (16,16). A re-cut overwrites these pixels, so they are set again after it. Clip approved: "Aprovar" (user, 2026-11-16).

Negative: outlines, black contour, front view, facing left, glow, music notes, text, ground, scenery, a drawn seat, crouching

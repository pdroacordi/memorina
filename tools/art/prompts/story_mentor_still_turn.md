---
id: story_mentor_still_turn
command: generate
target: res://assets/sprites/world/story/mentor/still_turn.png
size: 128x128
frames: 6
view: side
direction: west
source: procedural: tools/art/recolour_still.py
---
The keeper's slow turn from the lamp toward Ivo at the start of the awakening (STORY-38, `docs/knowledge/architecture/story38-the-keeper-wakes.md`): the opening's turn replayed in the stasis grey, his hand empty. The user: "a luta poderia demorar um pouquinho pra começar para o jogador poder assimilar o que está acontecendo" (2026-11-17); "De volta à lâmpada (Recommended)" (Q1: the opening's turn replays), "Mão vazia (Recommended)" (Q4). It plays inside `resources/cutscene/story/mentor_wakes.tres` (after a 0.5 s silence, a 1.0 s wait) as the `StillTurning` `StagedStrip` of `Props/Mentor` (intro `still_turn`); the scene now plays it after about 0.3 s of silence, then holds the turned Stasis 0.8 s so his face is seen. Approved: "Aprovar as quatro (Recommended)" (user, 2026-11-17).

Measured: 6 frames at 6 fps (1.0 s), 128x128 each, the same canvas as `turn.png`: feet on row 125, offset (-67, -126) from his feet at (720, 672), not flipped. Frame 0 is `still_at_lamp.png` at canvas (24..109, 6..125); frame 5 is Stasis exactly: `stasis.png` mirrored to face east, at canvas (24..109, 6..125), so the cut to the Stasis still at the strip's end does not jump. `turn.png` has 30 colours, the flute's included. Made: `turn.png` recoloured by `tools/art/recolour_still.py` with `--drop-colours=assets/sprites/world/story/mentor/memorina_in_hand.png` (the flute's own colours are dropped, not painted out by hand), frame 0 replaced by `still_at_lamp.png` and frame 5 by mirrored `stasis.png`, both at canvas (24, 6), then despeckled (`tools/art/despeckle.py`); `mentor_wakes_test.test_the_strips_meet_the_stills` holds both ends to the stills. The fallback, not needed: a PixelLab animate-with-text-v3 run from `still_at_lamp.png` at 2x (padded by `tools/art/pad_reference.py` onto 256x256) to mirrored `stasis.png`: "a tall still figure of pale grey wood and frost, its empty hand raised toward a lamp above, slowly lowers the arm and turns its pale mask and body around to face the other way; nothing in its hand; it stays in place", cut by `tools/art/cut_inhabitant.py` as `story_mentor_turn`. Our own art only, never a pack sprite (the packs' licences forbid AI training).
Negative: outlines, black contour, front view, glow, text, ground, scenery, lamp, light, flute, colour

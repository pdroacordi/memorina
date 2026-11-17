---
id: story_mentor_turn
command: animate3
target: res://assets/sprites/world/story/mentor/turn.png
size: 128x128
frames: 6
view: side
direction: west
reference: res://tools/art/sources/story/mentor_at_lamp_2x.png
action: a tall ancient guardian of wood and frost, its hand raised toward a lamp above, slowly lowers the arm and turns its pale wooden mask and body around to face the other way, holding out the small pan flute in its hand; its mantle of lichen barely moving; it stays in place
keep: 0-5
generate: 8
source: pixellab
---
The mentor's head turning slowly after Ivo's "Ei…" (05, Act 3; `docs/design/drafts/story32_34_talks.md`, STORY-34: "(Silêncio. A cabeça vira, devagar.)", approved by the user, 2026-11-17). "Contrato e provisório (Recommended)" (user, 2026-11-17; `docs/knowledge/architecture/story34-mentor-at-the-lantern.md`, Q4). It plays inside `resources/cutscene/story/mentor_turns.tres` (after a 1.2 s silence, before a 0.4 s hold) as the `Turning` `StagedStrip` of `Props/Mentor` (intro `turn`, its loop the last frame); until it is approved and drawn, that scene cuts straight to Holding.

Measured: 6 frames at 6 fps (about 1.0 s), 128x128 each, feet on row 125, frame (24, 6) is the stills' (0, 0), so the strip sits at offset (-61, -126) from his feet at (720, 672), as `raise.png` and `play.png` (`systems/story`, STORY-11). Frame 0 is `at_lamp.png` (facing west, arm and mask raised to the lamp, the hand at stills' canvas (-1..13, 14..30)); frame 5 is Holding exactly: `empty_hand.png` mirrored to face east with the flute's place at stills' canvas (73..87, 14..30), so the cut to the Holding still at the scene's end does not jump. The flute stays in the raised hand through the turn and is drawn in the strip (as in `raise.png`), since `memorina_in_hand.png` is hidden with AtLamp and Holding while the strip shows.

References: `tools/art/sources/story/mentor_at_lamp_2x.png` (the approved `at_lamp` still at 2x, made by `tools/art/pad_reference.py` onto the 128x128 canvas) and `tools/art/sources/story/mentor_holding_2x.png` for the last frame; our own art only, never a pack sprite (the packs' licences forbid AI training). PixelLab animate-with-text-v3 tends to turn a figure when asked not to and to paint effects (`systems/art-pipeline`); reject a clip with effects, cut by `python -I tools/art/cut_inhabitant.py <frames dir> mentor_turn tools/art/sources/story/mentor_at_lamp_2x.png <out> --keep=0-5 --floor=125 --centre=60-124`, and if no generation holds the figure through the turn, compose the strip with `tools/art/compose_strip.py` from at_lamp, two in-between frames and Holding.
Negative: outlines, black contour, front view, glow, text, ground, scenery, lamp, light

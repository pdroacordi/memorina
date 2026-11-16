---
id: playtests/2026-11-16-story07-ending-art
type: playtest
title: STORY-07 the whole ending with the final art - Ivo plays seated and lowers the flute in the gap, Alba sits close on the stone and is revealed by the widening frame, he turns to her during the pull-back, the duet rises to the open sky, the credits roll and the rest saves on the stone; no error
status: active
build: 9c6ba2cb + the uncommitted STORY-07 step 12 tree (the v2 seated clips, the daughter's clips, `CutsceneWalk.run`, Alba at `beside_stone` + 4 with no lift, the turn in the pull-back, the rise at zoom 1)
area_tested: "world restored, all four guardians restored, all five flashbacks seen, daughter_reunion heard and seen. tools/playtest/scripts/story07_ending_art.json (story07_ending.json plus shots of the raise, the gap, the reveal, the turn, the duet, the sky and Ivo alone): Down on the stone, the epilogue, the credits to their end, the rest, Left, Down again. A second run (scratch) burst 7.10-7.50 s every 0.05 s at the reveal."
tags: [story-07, epilogue, credits, art, cutscene, camera, playtest]
related: [architecture/story-07-epilogue, systems/ending, playtests/2026-11-16-story07-epilogue, playtests/2026-11-16-story07-credits, playtests/2026-11-16-story07-reunion-art]
created: 2026-11-16
updated: 2026-11-16
ratings: { fun: 0, fluidity: 4, aesthetics: 4 }
screenshots:
  - 2026-11-16-story07-ending-art/a01_closeup_play.png
  - 2026-11-16-story07-ending-art/a02_lowered_in_gap.png
  - 2026-11-16-story07-ending-art/pair_at_plus4.png
  - 2026-11-16-story07-ending-art/s16_talk3_alba.png
  - 2026-11-16-story07-ending-art/a06_duet_play.png
  - 2026-11-16-story07-ending-art/a07_sky_top.png
  - 2026-11-16-story07-ending-art/a08_alone.png
  - 2026-11-16-story07-ending-art/c12_after_rest.png
  - 2026-11-16-story07-ending-art/edge_7.10-7.50.png
---

# STORY-07: the whole ending with the final art

Two windowed runs, each with its own `APPDATA`. No SCRIPT ERROR; the only engine output is the usual "resources still in use at exit". Event times match `playtests/2026-11-16-story07-epilogue` within 0.05 s, so the Z presses of `story07_ending.json` hold.

## What the art changed

- **Ivo plays seated** (`a00_raise`, `a01_closeup_play`): Down seats him facing west; the close-up opens on the raise (`sit_memorina_raise` at 1.95 s), then the playing loop under the four notes. In the gap he lowers the flute (`sit_memorina_lower` at 5.03 s, `a02_lowered_in_gap`) and sits at rest through the silence: "Na lacuna ele para" now shows. At the duet he raises it again (33.2 s) and plays until the scene ends; the end lowers it (50.8 s).
- **Alba sits on the stone, close** (`pair_at_plus4`, `s16_talk3_alba`): at `beside_stone` + 4 her lap rests on the stone's end with her feet down in the grass, her knees about 4 game px from his. Seated, her head stands 2 art px below his, as standing she is shorter. The playtest's "one body width apart" is gone. At zoom 3 both heads stay clear of the box.
- **The reveal** (`edge_7.10-7.50`, `e_7.25_no_sliver`): she is placed at 7.22 s on the frame the pull-back starts. Nothing of her shows at 7.25 s; from 7.30 s the widening frame uncovers her from the right edge. At + 2 her sprite sat exactly on the close-up's edge, so + 4 keeps a 2 px margin.
- **The turn** (`a04_he_turns`): Ivo faces west until 1.5 s into the pull-back, then turns to her (9.65 s), before the first line opens at 10.24 s. It is still a cut, but it reads as him noticing her instead of landing with the box.
- **The duet and the sky** (`a06_duet_play`, `a07_sky_top`): he plays toward her while she sings (`beside_sing`, the mouth opening); the frame rises at zoom 1 to the room's top and ends on the open sky, the sun and two clouds, the fall and its cliff on the right ("até o céu"). She is gone at her release while the frame is up; it comes back to him alone on the stone (`a08_alone`), still playing, inside the flute's last C.
- **The credits and the rest** are unchanged (`c06_godot`, `c12_after_rest`): the roll, the year, the black, the rest on `garden_stone` (`bench=garden_stone ending_finished=true epilogue_due=false` at 116.4 s), Left stands him, Down rests again.

## What frames cannot show

Sound (the hush, the four notes, the duet against her exit, the title theme coming in), the feel of the rise at zoom 1 (it now also widens while it climbs), and whether Ivo's hands and flute, one small block at 22 art px, read in motion at zoom 2. STORY-28 and STORY-31 hold them.

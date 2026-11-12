---
id: playtests/2026-11-12-story05-flashback-2
type: playtest
title: STORY-05 flashback 2 - the ribbon by the frozen lake's arena door, Ivo takes it and it flies into white, Alba in the flower bed, three yellow flowers across the pool, the far frame on her hand at her chest, the tie, the colour failing in a soft circle, Ivo kneeling back by the door with the ribbon; the region is restored and so in colour, so the ribbon is not the one colour there
status: active
build: e8d212fb + uncommitted STORY-05 step 8 tree
area_tested: "lake_glacier (west lip, Frost restored, flashback 1 seen): the Ribbon staging, RibbonTalk, flashback_2_crossing, the travel under white; garden_past: flashback_2_opening, flashback_2_ask (auto start), three flower talks (teleports), flashback_2_pick_1..3, flashback_2_chest, flashback_2_pale (auto start after a teleport back), flashback_2_tie, flashback_2 (the leaving); the travel back and flashback_2_returning."
tags: [story-05, flashback, cutscene, memory-bloom, ribbon, alba, playtest]
related: [architecture/story-05-playable-flashbacks, systems/cutscenes, playtests/2026-11-12-story05-flashback-1]
created: 2026-11-12
updated: 2026-11-12
ratings: { fun: 0, fluidity: 3, aesthetics: 2 }
screenshots:
  - screenshots/2026-11-12-story05-flashback-2/c00_crossing.png
  - screenshots/2026-11-12-story05-flashback-2/c01_crossing.png
  - screenshots/2026-11-12-story05-flashback-2/c02_crossing.png
  - screenshots/2026-11-12-story05-flashback-2/c05_crossing.png
  - screenshots/2026-11-12-story05-flashback-2/o00_opening.png
  - screenshots/2026-11-12-story05-flashback-2/o04_opening.png
  - screenshots/2026-11-12-story05-flashback-2/a00_ask.png
  - screenshots/2026-11-12-story05-flashback-2/p3_pick.png
  - screenshots/2026-11-12-story05-flashback-2/h01_chest.png
  - screenshots/2026-11-12-story05-flashback-2/h04_chest.png
  - screenshots/2026-11-12-story05-flashback-2/t00_pale.png
  - screenshots/2026-11-12-story05-flashback-2/t03_tie.png
  - screenshots/2026-11-12-story05-flashback-2/l01_leaving.png
  - screenshots/2026-11-12-story05-flashback-2/l03_leaving.png
  - screenshots/2026-11-12-story05-flashback-2/r00_return.png
  - screenshots/2026-11-12-story05-flashback-2/r02_return.png
  - screenshots/2026-11-12-story05-flashback-2/g1_garden_grey.png
  - screenshots/2026-11-12-story05-flashback-2/g2_garden_tree.png
  - screenshots/2026-11-12-story05-flashback-2/g3_garden_fall.png
  - screenshots/2026-11-12-story05-flashback-2/g4_past_stone.png
  - screenshots/2026-11-12-story05-flashback-2/k1_pocket.png
  - screenshots/2026-11-12-story05-flashback-2/k2_pocket_crossing.png
---

## What was tested

`tools/playtest/scripts/story05_flashback_2.json` (game.tscn, en, sword and Memorina, Frost restored, `flashback_1` seen, Ivo at (5800, -1650) on lake_glacier's west lip): Up at the ribbon at 2.0 s (an Up at 0.4 s, under the arrival fade, was ignored on the first run); the crossing; the travel; the opening; the ask's auto start, Z; teleports to the three flowers and Up at each; the chest scene; a teleport back beside her; Z through four lines; the leaving; the return. Three runs: the second after moving the Up past the fade, the third after un-mirroring the flight strip in the west-facing rooms and moving the flowers and `far_side` 30 px west.

Read against `docs/design/drafts/camada_pessoal.md` §2, flashback 2's Cinema line.

## Findings

What reads:
- **The call and the take.** The blue strip flutters by the doorway with the Up glyph; the bars come in and the frame closes at zoom 2 (`c00_crossing`); Ivo raises his hand with the ribbon in it (`c01_crossing`).
- **The ribbon flies to white.** It leaves his hand upward, a ring of colour following it and the frame rising with it (`c02_crossing`), then the ring spreads and white covers it (`c05_crossing`). The log shows Ivo still at the door through it.
- **The memory opens on her.** Her hair at zoom 3, crouched in the bed (`o00_opening`), then both (`o04_opening`). Her ask auto-starts as the opening ends (`a00_ask`).
- **The flowers.** Each Up kneels Ivo briefly and the flower is gone (`p3_pick`).
- **The far frame.** After the third flower the frame widens across the pool: Alba small on the left, Ivo on the far lip, turned away; she sits, holds her chest and stands (`h01_chest`, `h04_chest`). Both stay inside the frame after the 30 px move.
- **The talk and the tie.** Coming back starts "You're pale." (`t00_pale`); at "Give them here." she plays her ribbon clip and holds it out (`t03_tie`).
- **The leaving.** The colour keeps a soft circle on her (no hard rectangle, the flashback 1 finding) and greys from the edges (`l03_leaving`).
- **The return.** Ivo is back at (5812, -1632) facing west, kneeling (`r00_return`), then standing with the ribbon in his raised hand (`r02_return`), then free.

What does not read:
- **The grey.** A restored region is in colour, so the ribbon is not "a única cor no cinza" there: by the user's "Em toda região restaurada", every place it shows is restored. Only a shield-less grey spot (or a local `MemorySource` at -1 around it) would make it read as the only colour. A decision for the user.
- **Placeholders.** The ribbon hangs in the air above Ivo's head with no branch; the flight strip is a few blue pixels; the flowers are tiny; Ivo carries no bouquet; the ribbon in his hand is painted on. The garden art in progress replaces these.
- **No stepping stones.** The pool is a one-row dip crossed by a jump lip to lip; the run teleported.
- **Scale.** The far frame at zoom 1 makes her chest gesture 30 px tall: readable as a sit-and-rise, not as a hand on the chest.
- **Sound.** The muffle, the music and the silence are not judged from frames.

## Ratings rationale

- fun 0: not judgeable from frames.
- fluidity 3: every hand-off ran in order on all runs (talk, beat, crossing, travel, opening, auto talks, picks, chest, tie, leaving, travel, returning), and Ivo returned to the same place and facing.
- aesthetics 2: the structure and the leaving read; the placeholder ribbon and flowers, and the colour of the restored region, weaken the two images the Cinema line rests on (the blue alone in the grey, the bouquet).

## Follow-up: the garden art and the grey pocket (2026-11-12)

Three runs of `game.tscn` with ad hoc timelines (not kept): village_garden then garden_past with flashback 1 due; village_garden with four guardians restored and flashbacks 1-4 seen; lake_glacier with Frost restored, flashback 1 seen, Up at the ribbon.

- **The garden reads.** At memory 0 the old tree, the fallen swing, the beds and the fall stand grey and still (`g1_garden_grey`); with flashback 3 seen the swing hangs from the branch (`g2_garden_tree`). The fall pours from the ledge's notch into the shallow pool, the splash on the waterline, the ledge's right edge inside the rock (`g3_garden_fall`). In the past Alba sits on the flat stone by the coloured fall (`g4_past_stone`).
- **The pocket works.** In restored lake_glacier a grey disc surrounds the ribbon, which is the one colour in it; the bow and its two ends read at a glance, about Ivo's height (`k1_pocket`). In the crossing the bloom carries colour out of the pocket with the flying ribbon (`k2_pocket_crossing`), then the room is in colour under the white.
- **Not judged:** the waterfall's and flowers' motion (frames only), and the pocket's 3 s fade on the return (the run ended under the white). The twig is small against the rock over the doorway; the yellow flowers across the pool are still the placeholder.

## Revisited

The garden was rebuilt the same day (a bank over a lake, the fall at the right, a sky per flashback): `playtests/2026-11-12-story05-garden-rebuilt`. The timeline was moved to the new room; the positions above are the old room's.

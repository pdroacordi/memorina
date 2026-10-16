---
id: playtests/2026-10-16-ui13-villager-portraits
type: playtest
title: UI-13 villager portraits - the six villagers' busts in the dialogue box, top and bottom; pixel-exact, on the 2x grid, the text unmoved
status: active
build: 024781a (UI-13 uncommitted; the four padded portraits of 15:04:07 included)
area_tested: "village_square (boy, water carrier), village_lane_west (seller), village_tavern (taverner), village_bakery (baker, the opening errand and the later visits), village_elder (the elder's story: the boy and the girl); 0.8 and 0.6; the box at the top (in play) and at the bottom (forced)"
tags: [ui-13, dialogue, portrait, villagers, art, 2x-rule, playtest]
related: [systems/dialogue, systems/art-pipeline, gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid, playtests/2026-10-15-story09-village-voices, playtests/2026-10-16-story16-opening]
created: 2026-10-16
updated: 2026-10-16
ratings: { fun: n/a, fluidity: n/a, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-16-ui13-villager-portraits/top_boy.png
  - screenshots/2026-10-16-ui13-villager-portraits/top_water_carrier.png
  - screenshots/2026-10-16-ui13-villager-portraits/top_seller.png
  - screenshots/2026-10-16-ui13-villager-portraits/top_taverner.png
  - screenshots/2026-10-16-ui13-villager-portraits/top_baker_errand.png
  - screenshots/2026-10-16-ui13-villager-portraits/top_girl_elder_story.png
  - screenshots/2026-10-16-ui13-villager-portraits/top_water_carrier_at_06.png
  - screenshots/2026-10-16-ui13-villager-portraits/bottom_water_carrier.png
  - screenshots/2026-10-16-ui13-villager-portraits/bottom_taverner.png
  - screenshots/2026-10-16-ui13-villager-portraits/bottom_girl_elder_story.png
  - screenshots/2026-10-16-ui13-villager-portraits/busts_beside_world_sprites.png
  - screenshots/2026-10-16-ui13-villager-portraits/cast_board_from_pngs.png
---

# UI-13: the villager portraits

"Sim: retratos para os aldeões que falam (UI-13), quadro primeiro para eu aprovar." (user, 2026-10-16). The baker, the taverner, the water carrier, the seller, the boy and the girl now have busts in the dialogue box's 48x48 slot.

## Runs

All runs were windowed, with `APPDATA` redirected to a scratch folder. Every run exited 0. The only error line in the logs was the usual "4 resources still in use at exit".

- `village_voices.json` (0.8) and `village_voices_06.json` (0.6): each villager's talk.
- `story16_bakery.json`: the baker's errand in the opening.
- `story16_elder.json`: the elder's story, with "Until he what?" (boy) and "Bring back the end of the story!" (girl).

No new timeline was needed.

**Code state.** A sibling padded `water_carrier.png`, `taverner.png`, `daughter.png` and `mentor.png` at 15:04:07 (re-imported 15:04:45), mid-session (`gotchas/a-centred-texture-rect-can-land-half-an-art-pixel-off-the-grid`).
- The first top-placement runs (15:00-15:01) saw the old widths.
- The bottom runs (15:07-15:08) and the top re-runs (15:09-15:10) saw the padded files. The verdicts below come from those runs.
- Nothing under `assets/sprites/hud`, `resources/dialogue`, `scenes/ui/dialogue_box`, `scenes/world/dialogue` or `i18n` changed after the re-runs.

**The bottom placement cannot be reached with these six in play.** The placement rule puts the box at the bottom only when the speakers stand above the middle of the screen. Every villager stands on a floor where the camera is clamped to the room's bottom, so their feet are 84 px below the middle:
- square and lane: camera centre y 204, floor 288;
- tavern: 12588, floor 12672;
- bakery: 12204, floor 12288.

So every talk opened at the top, as `systems/dialogue` predicts. To see the bottom placement, a `-s` driver started the real playtest runner on the same timelines and called `DialogueBox.place(BOTTOM)` every frame while the box was open. Everything else was the real talk: speaker, line, typing, plate. That is a forced layout, not a placement the game chose.

## What was measured

- **Fit: pixel-exact in the slot, at the top and at the bottom.** Every opaque pixel of each source PNG was compared with the screenshot. Each one lands as a 2x2 window block at the `STRETCH_KEEP_ASPECT_CENTERED` position (scale 1 game px per PNG px, the slot at window x 72, y 120 on top or 464 at the bottom). The mean colour difference was 0.00, with 0 pixels off, for:
  - all six villagers, Ivo and the elder at the top;
  - the five village busts and the girl, boy and Ivo at the bottom.

  Nothing is cut, squashed or drawn over. The busts are 96 px tall; their widths are 68 to 84 px, centred.
- **On the 2x grid since the padding.** Counting colour edges inside the slot by `(x - 72) % 4`:
  - in the 15:00 run, the water carrier (66 px wide) and the taverner (82 px) had every edge at phase 2: half an art pixel off the box (3288/3288 and 4228/4228 edges);
  - in every later run, all edges are at phase 0, for all six villagers.

  The reviewer's fix works.
- **Plate and slot do not overlap.** The slot runs from art y 30 to 78 on top; the plate is below it (79 to 95). At the bottom the plate is at 99 to 115 and the slot starts at 116. Like the cast busts, the villagers' heads touch the frame's inner line at the slot's top. One art px of paper shows under each bust.
- **The text did not move.** For each of the seven lines in `village_voices` and the three in `_06`, the text area (window x 280..1150 over the paper) was diffed against the STORY-09 screenshots, which had no portrait. 0 pixels differ.
  - The frame above the slot is identical too.
  - The only change under the box is a 16 px world particle (window x 334..338, y 370..374), not the plate.
  - At the bottom the text starts at window (288, 480), 86 art px (`TOP_SHIFT`) below the top case's (288, 136).
- **The right bust for the speaker.** The baker's errand switches correctly between the baker and Ivo, including the baker's echo, "Just the round one." (`DLG_BAKER_ERRAND_03`, her line). In the elder's house the boy says "Until he what?" and the girl says "Bring back the end of the story!" with the Boy and Girl plates.
- **At 0.6** the busts stay in full colour while the square greys behind them (`top_water_carrier_at_06`). The cast busts do the same: the box is HUD and never greys.

## Reading (judgement, from stills)

**The busts read as the villagers in the world** (`busts_beside_world_sprites`, each bust beside a 2x crop of its sprite):

| Villager | Bust and sprite |
|---|---|
| Boy | brown hair, cream shirt, dark brown vest |
| Water carrier | white cloth cap, cream blouse, olive bodice. The sprite's dress samples (78,67,51) and (63,61,51); the bust's bodice (108,86,46) and (65,56,41). |
| Seller | white cap and a red bodice over a cream blouse, matching her red skirt and white apron. Her hair reads near-black in the sprite (32,29,26) and warm brown in the bust. A small difference, visible only side by side. |
| Taverner | brown hair, full beard, cream shirt, brown apron. Mostly hidden behind his counter in the world, so the bust adds what the sprite can't show. |
| Baker | white cap, brown dress, cream blouse, the flour smudge her contract asks for |
| Girl | brown bob, red pinafore, like the red dress she wears at the elder's table |

**Of a piece with the cast** (`cast_board_from_pngs`: every portrait PNG on the slot's paper colour at 2x, composed from the sources; the render is proven 1:1 above). The villagers follow the same conventions as Ivo, the daughter and the elder:
- the same bust facing right, in three-quarter view;
- 2x2 pixel doubling, no outline;
- warm palette;
- the head on the slot's top edge, the bust cut at its bottom.

They do run busier. Measured at art resolution:

| | Isolated single art pixels | Colours |
|---|---|---|
| Villagers | 29-38% | 42-53 |
| Ivo, the daughter, the elder | 11-20% | 35-44 |

The villagers' eyes also have a catchlight that the daughter's lacks. The contract's negative list includes "speckle". At box size this reads as more detailed, not as noise. The user approved these busts ("Aprovar (Recommended)"), so this is a note for any future portrait, not a defect.

**Three women, one template.** The water carrier and the seller share a head:
- the same cap, bun and profile;
- 55.8% of their head pixels match at zero shift, the highest of any pair measured (seller-baker 51.4%, boy-girl 51.0%, daughter-girl 37.7%).

In a talk they are told apart by the bodice colour (olive against red) and the plate. The board's first fault (the baker and the seller sharing a face) is fixed: the baker is now round-faced and floury. The user approved the board as it is, so this is recorded, not filed.

## What screenshots cannot show

- Whether a portrait popping in on the first typed frame feels abrupt. Every frame here was taken after the line had started typing.
- How the busts read at a real player's viewing distance and screen size.

These need a human look; the ratings above judge stills only.

## Harness notes

- `story16_bakery.json`'s labels now trail the talk by about one line. The errand gained the baker's echo of "Just the round one.", so the run ends with the talk still open (`blocked=true`). It still shows the baker's bust; retime it before reusing it for the notice.
- The bottom-placement driver is described in the playtester agent's limitations list.

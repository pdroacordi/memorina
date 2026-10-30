---
id: playtests/2026-10-30-grd04-autumn-summer-fights
type: playtest
title: GRD-04 - both new guardians fought to RESTORED with the lesson and the talks; the gust carries Ivo to the wall and the wall-climb recall lands
status: active
build: e359d3c + uncommitted GRD-04 working tree
area_tested: "wind_orchards/orchard_arena (Leaf Guardian, Ivo from -9574), summer_caldera/caldera_arena (Sun Guardian, Ivo from 3226): whole fights, the lesson, the first talk with its gesture and the repeat"
tags: [guardians, grd-04, gust, recall, wall-climb, lion, playtest]
related: [systems/guardians, architecture/grd-04-autumn-and-summer-guardians]
created: 2026-10-30
updated: 2026-10-30
screenshots:
  - playtests/screenshots/2026-10-30-grd04-autumn-summer-fights/fights_and_talks.png
  - playtests/screenshots/2026-10-30-grd04-autumn-summer-fights/gust_leaves_readable.png
  - playtests/screenshots/2026-10-30-grd04-autumn-summer-fights/flutes_round2.png
---

## What was tested

`tools/playtest/scripts/guardian_fight_talk_driver.gd` with `guardian_bot_autumn.json` / `guardian_bot_summer.json`
(260 s, `BOT_GOD=1`, `BOT_CHOICE=1`, locale en). The driver now lets go of the stick while a gust blows, as a player
would. No errors in either run.

## Results

- **Autumn: PASS.** The gust (the third move, after two) carried Ivo 590 px along the floor to the west `FightWall`;
  the recall opened at the wall at 8.3 s, the press recalled WALL_CLIMB and he hung on the wall's veil with the
  prompt over him (`fights_and_talks.png`, top row). Three cures, RESTORED at 88 s, the lesson, the first talk (Leaf
  Guardian portrait, the six lines, "Let the wind take it" and its reply) and the repeat. Later gusts, escaped by
  choice, hit the bot each time: it does not climb (a bot limit, not the move).
- **Summer: PASS.** Two cures, RESTORED at 74.5 s, the lesson (the sheet over the lion), the first talk (top box, the
  lion whole under it), "Walk into the sun" and the repeat. The charge hit only with its box open (`hb=true` on every
  charge hit). The bot, holding 62 px (tuned for Frost), took contact hits from the lion's flank every second: the
  lion's body is 132 px long, and a player strikes it from outside that (Ivo's reach on it ~130 px).
- **The gust's leaves, first build: FAIL.** 4x2 px flecks in mid-tones vanished against the grey floor outside the
  guardian's shield. **Second build: PASS.** 6 px flecks in a light and a dark pair read in value alone
  (`gust_leaves_readable.png`).
- **Flutes: redrawn** after the user's "Refazer as flautas" (`flutes_round2.png`), then "Aprovar a arte".

## What screenshots cannot show

The gust's push feels like being blown, not teleported: the carry ramps through the ground drift, and the press at
the wall reads as the same jump the player already knows.

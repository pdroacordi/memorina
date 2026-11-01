---
id: playtests/2026-11-01-grd06-restoration
type: playtest
title: GRD-06 - the mentor fought to the end by the bot, then the world restoration scene in the lantern
status: active
build: f7255d2e + uncommitted restoration scene, call_phrase window hold, lamp
area_tested: "frost_edge/lighthouse_top: the whole mentor fight (bot, BOT_GOD=1), the restoration scene"
tags: [guardians, grd-06, finale, cutscene, playtest]
related: [systems/guardians, systems/cutscenes, bugs/the-final-calls-next-phrase-ran-out-while-the-mentor-sang-it]
created: 2026-11-01
updated: 2026-11-01
screenshots:
  - playtests/screenshots/2026-11-01-grd06-restoration/placed_at_zoom_2.png
  - playtests/screenshots/2026-11-01-grd06-restoration/lantern_unlit.png
  - playtests/screenshots/2026-11-01-grd06-restoration/lantern_lit.png
  - playtests/screenshots/2026-11-01-grd06-restoration/rest_after.png
---

# GRD-06: the restoration scene

`guardian_fight_bot_driver.gd` on `guardian_bot_mentor.json` (BOT_GOD=1, BOT_RESTORED_MS=22000, BOT_MAX_SHOTS=400); the bot now answers the phrase each `call_opened` shows.

## What happened

- The first run never finished: every two-track window relapsed ~3 s after the chosen track, before the first final phrase's window opened (`bugs/the-final-calls-next-phrase-ran-out-while-the-mentor-sang-it`). Fixed; the next runs went winter window (6 s), the revelation (26 s, back to pressure at 34 s), a two-track window at 41 s answered on track A, both final phrases answered, RESTORED at 69 s.
- The scene ran 69-83 s: bars and black; in the black the mentor was teleported from x 11219 to his spawn 11760 and Ivo stood 104 px west of him; the fade in at zoom 2 on the two; his winter song while the frame pulled back to the whole lantern at zoom 0.5; the lamp lit with its halo; the frame back on the two; `perform` through the scene, `perform_end` at 83 s, then `restored`.
- First look at zoom 0.5: the letterbox's top bar hid the lamp's cap (the frame is clamped at the room's top). The lamp now hangs 50 px lower on a repeated chain link from the roof; the second run shows it whole.

## What screenshots cannot show

The song is his note voices at 0.6 s a beat, about 4.5 s, under the 4.5 s pull back, so the lamp lights on the last note's ring. The scene feels short and quiet: no music bus exists yet (systems/cutscenes defaults). The zoom 0.5 frame draws the 2x art one game pixel per art pixel, so it stays crisp.

## Open

- The lamp's art waits for the user's approval.
- The mentor's palette is pale in colour as in grey; his restored look reads only by pose.

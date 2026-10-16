---
id: playtests/2026-10-16-ui11-item-and-intent
type: playtest
title: UI-11 item and intent - the baker's errand tells the round loaf after the talk, then the way home; the pause menu shows the intent before and after
status: active
build: 6f95edf (UI-11 uncommitted)
area_tested: "village_bakery: the pause menu before the errand, the baker's errand talk, the bread notice, the intent notice, the pause menu after; en and pt_BR"
tags: [ui, hud, notice, intent, item, pause, playtest]
related: [systems/notices, systems/notebook, systems/screens, systems/story, systems/dialogue]
created: 2026-10-16
updated: 2026-10-16
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
---

# UI-11 item and intent

Timelines: `tools/playtest/scripts/ui11_item_and_intent.json` (en, every frame) and `ui11_item_and_intent_pt.json` (pt_BR, four frames), both `"clock": "real"`, starting in village_bakery (x 6600) owning nothing with `daughter_errand` heard. The runner's `log` now prints `notice=<alpha> '<text>' waiting=[...] intent=<key>`. Stills: `screenshots/2026-10-16-ui11-item-and-intent/` (pt_BR in `pt_BR/`).

## What was measured

- **Before the errand** (her talk heard, so the intent is the bread): no notice at the start (the world seeded the intent silently; `waiting=[]`). The pause menu shows "The round loaf." centred under its box (`01_pause_round_loaf`); pt_BR "O pão redondo.".
- **In the talk:** the grant lands on "Just the round one." (`03_just_the_round_one`): `waiting=[item 2]` at t 7.65 and nothing on screen beside the dialogue box and its plate. The notice waits for the talk.
- **After the talk** (Z at 7.8): at t 8.00 the bread notice is at alpha 0.55, sliding in; `waiting=[intent home]`; the menu's intent (the one last told) is still `INTENT_BREAD`, and turns to `INTENT_HOME` only when its notice shows (11.65). At 8.25 and 9.35 it shows at 1.00: the round-loaf icon (the user's 16x16 art at 2x: a golden domed loaf with a scored top, readable against the timber wall), "Round loaf" / "Pão redondo" and the notebook quill to its right (`04`, `05`). At 10.65 it is leaving (0.16).
- **The intent:** at 11.65 the second notice shows at 1.00, "Home." / "Para casa." (design 05 draft 3's text), with no icon, right-aligned on the same row (`07`, `08`); the quill is still fading out beside it.
- **Pause after:** the menu shows "Home." under the box (`09_pause_home`); the notice behind the dim stays at 1.00 for the whole pause (it is pausable) and is at 0.67 half a second after resuming.
- No script errors in either run.

## Reading

- The order reads as intended: the loaf, then where to take it. Neither appears over the box.
- The row and the quill read as one strip at the top right; the life notes keep the top left.
- The 8 px font at 2x is small for a notice the player must catch in 2 s; UI-12 (a more readable font) applies here too.
- The intent line under the pause box falls on the room's black void band in the bakery (the room is 384 px tall); in a room with ground below the box it would sit on the dimmed room. Cream with the dark outline should hold on both, not checked on a bright room.
- Re-run 2026-10-16 after the review fixes (told-intent menu, withdraw only before the slide-out) with the user's icons in `assets/sprites/hud/items/`: same timings; the loaf icon sits on the row's height and its warm brown stands apart from the cream text and the grey quill.
- The patched tilde of "Pão" rises to the row's top edge but is not clipped.
- Not judged from stills: whether 0.3 s in, 2.0 s hold and 0.5 s out feel right, and whether the slide is noticeable at 12 art px.
- Not run: a talk that starts while a notice shows (covered by `notice_watcher_test`), the song's intent change after the cutscene.

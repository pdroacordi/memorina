---
id: playtests/2026-11-13-story04-bearer-fragments
type: playtest
title: STORY-04 bearer fragments - all four run end to end (call, engraving, return to the same spot and facing, Memories page, skip, no replay); the captions were hidden by the letterbox and show after the fix (EngravingView after Letterbox)
status: active
build: 8dc45a57 + uncommitted STORY-04 tree (bearer catalog, cutscenes, music cues, notebook entries); imported 2026-11-13, no file under scenes/resources/assets/globals changed after the import
area_tested: "village_garden (3470, -530) with one guardian restored and its song known: the world performance, BearerFragmentDirector (wait for the pulse, start gates), bearer_<g>_call, the travel to bearer_stage, the engraving bearer_<g> (4 frames, captions, ink layers, pan, clear, fade to black), the travel back, bearer_<g>_returning, Music requests, the notebook Memories page, Skip scene from the pause menu, a second performance of the same song."
tags: [story-04, bearer, engraving, cutscene, letterbox, caption, notebook, music, playtest]
related: [architecture/story-04-bearer-fragments, systems/cutscenes, systems/story, systems/notebook, systems/music, systems/flashbacks]
created: 2026-11-13
updated: 2026-11-13
ratings: { fun: 0, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-11-13-story04-bearer-fragments/summer_call_zoom.png
  - screenshots/2026-11-13-story04-bearer-fragments/summer_call_paper_fade.png
  - screenshots/2026-11-13-story04-bearer-fragments/summer_frame1_no_caption.png
  - screenshots/2026-11-13-story04-bearer-fragments/forced_captions_frost_en_pt_BR.png
  - screenshots/2026-11-13-story04-bearer-fragments/frost_frame1.png
  - screenshots/2026-11-13-story04-bearer-fragments/frost_frame2.png
  - screenshots/2026-11-13-story04-bearer-fragments/frost_frame3.png
  - screenshots/2026-11-13-story04-bearer-fragments/frost_frame4.png
  - screenshots/2026-11-13-story04-bearer-fragments/bloom_frame1.png
  - screenshots/2026-11-13-story04-bearer-fragments/autumn_frame1.png
  - screenshots/2026-11-13-story04-bearer-fragments/autumn_frame3.png
  - screenshots/2026-11-13-story04-bearer-fragments/summer_clear.png
  - screenshots/2026-11-13-story04-bearer-fragments/summer_return.png
  - screenshots/2026-11-13-story04-bearer-fragments/frost_notebook_en.png
  - screenshots/2026-11-13-story04-bearer-fragments/autumn_notebook_pt_BR.png
  - screenshots/2026-11-13-story04-bearer-fragments/skip_pause_menu.png
  - screenshots/2026-11-13-story04-bearer-fragments/skip_returned.png
  - screenshots/2026-11-13-story04-bearer-fragments/fixed_frost_frame1_caption_en.png
  - screenshots/2026-11-13-story04-bearer-fragments/fixed_bloom_frame1_caption_pt_BR.png
  - screenshots/2026-11-13-story04-bearer-fragments/fixed_autumn_frame3_caption_pt_BR.png
  - screenshots/2026-11-13-story04-bearer-fragments/fixed_summer_frame1_caption_en.png
---

## What was tested

Five timelines, all `"clock": "real"`, Ivo at (3470, -530) in village_garden, owned sword and Memorina, `flashback_1..5` seeded as seen (so no flashback is due), one guardian restored and its song known:

| Timeline | Guardian / song | Locale | Extra |
|---|---|---|---|
| `story04_bearer_frost.json` | FROST / FREEZE | en | faces west first (Left 0.07 s) |
| `story04_bearer_bloom.json` | BLOOM / ROOT | pt_BR | |
| `story04_bearer_autumn.json` | AUTUMN / RELEASE | pt_BR | faces west first |
| `story04_bearer_summer.json` | SUMMER / SHADOW | en | after the notebook: closes it and plays SHADOW again, watched for 30 s |
| `story04_bearer_skip.json` | SUMMER / SHADOW | en | Escape in engraving frame 1, Down, Z (Skip scene), then the notebook |

Each timeline draws the Memorina (C), plays the six notes 0.4 s apart and lets the instrument sheathe itself, then takes a screenshot every 0.5 s from 1 s before the call to the end of the returning, logs every 0.25 s, and opens the notebook (E) 2 s after the return. The runs went through a scratch `-s` probe driver that loads the runner and prints every 0.25 s the director's stage, the cutscene id, the `EngravingView` and caption state (text, alpha, rect, line count), the letterbox, Ivo's position and facing, and `Music.playing()` / `Music.muffled()`. Two more frost runs (en and pt_BR) set `CaptionArt.z_index = 10` from the probe, to read the captions; those frames are labelled "forced".

## Findings

### Bug (fixed in 643d9bf0): no caption was ever visible

In all five runs the bottom bar stays black through all four frames (`summer_frame1_no_caption`). The caption is set: the probe shows `cap_vis=true`, the right text per frame in each locale, `lines=1` and alpha up to 1. The pixels of the 72-window-px bottom bar are all the letterbox colour.

Cause: `Caption` sits at game y 324..360 (`CaptionArt` scale 2, offset_top 162). That is exactly the bottom bar. `EngravingView` is a `CanvasLayer` child placed before `Letterbox` in `game.tscn`, and both bars are opaque (`Color(0.02, 0.015, 0.03)`), so the bar draws over the caption. The plan asks for both things at once: the view "sits under the bars" and the caption is "centred in the bottom bar's 36 px". `engraving_caption_fit_test` measures only the fit, so it cannot catch this. Reproduced 5/5.

With the order forced (`forced_captions_frost_en_pt_BR`), the captions read well: cream 8 px text, centred, one line each. The longest Portuguese caption, "A aldeia do outro lado não tinha ponte, e o inverno chegava tarde.", fits with margin on both sides. The probe reports `lines=1` for all 20 captions seen (en for FROST and SUMMER, pt_BR for all four of FROST, BLOOM and AUTUMN).

### What works, in all four fragments

- **Trigger.** The fragment waits for the pulse: the stage goes WAITING when the performance ends, and the call starts when the pulse is gone. Call start in real seconds after the first draw: SUMMER ~20.5, FROST ~32.7, BLOOM ~32.5, AUTUMN ~37.2. That is the excerpt freeze plus the pulse (9, 16, 17 and 21.2 s). The FREEZE ice disc is still fading at the call's first frame. No fragment ever started while the Memorina was drawn.
- **The call** (`summer_call_zoom`, `summer_call_paper_fade`):
  - The bars come in, and the frame closes on Ivo at zoom 2 within ~1 s. He stays centred, with his facing unchanged.
  - The region music is muffled to 0.90 within ~0.5 s.
  - The fade to paper takes ~1.2 s, from ~2.3 s.
  - CALLING lasts 3.5 s in every run.
- **The engraving.**
  - Length: 32.3-32.4 s, from ENGRAVING to RETURNING.
  - Frames: 4, ~7.5 s each. Frame 1 dithers in from paper, and frames 2-4 dither over the previous frame. The clear dithers the ink back to paper in ~1 s (`summer_clear`), then fades to black in ~0.8 s.
  - Ink colours: blue-grey for winter (`frost_frame1..4`), green for spring (`bloom_frame1`), rust for autumn (`autumn_frame1`, `autumn_frame3`), ochre for summer. All read on the paper.
- **Only ink moves.** I aligned consecutive 0.5 s shots by the pan shift and classified the pixels that still differ. Each one is ink in one shot and paper in the other, so the grey never moves.
  - Moving pixels per 0.5 s, in game px: FROST 160-270, BLOOM 120-300, AUTUMN 130-640, SUMMER frames 1 and 3: 50-120.
  - SUMMER frames 2 and 4 have exactly 0 residual: no ink layer, as specified.
  - The probe confirms the layers: flakes/snow on all four frost frames, snow then petals for bloom, wind+leaves / birds / leaves / leaves+wind for autumn, embers on summer frames 1 and 3.
- **The pan.** Every frame pans in one direction with an ease, in whole game px, with no stepping visible between 0.5 s shots.
  - Measured peak speed: ~28-34 game px/s (FROST frame 3, AUTUMN frame 4, SUMMER frame 4). The slowest is ~8 px/s at the start and end of a frame.
  - Whether that feels "slow" is an inference from frames, not an observation. It is clearly visible motion, about 5% of the screen width per second at its peak.
- **The return** (`summer_return`):
  - Ivo is back at the exact position (3470.0, -512.0 and 3463.17, -512.0 in the west-facing runs). His facing is preserved: -1 for frost and autumn, as he stood. This was checked in a crop: the nose points west before, during the call, and after.
  - The cover clears in ~0.5 s, with the bars still in.
  - RETURNING lasts 1.76-1.77 s. `PlayerInput.blocked` ends ~0.5 s later, when the bars leave.
- **Music** (from the probe, not heard):
  - The region theme (`region_home_village.tres`) plays until the travel. `bearer_<g>.tres` becomes `Music.playing()` on the stage and stays through the returning, and the muffle drops to 0 as the engraving starts.
  - The region theme is back when the returning ends.
  - The 1.5 s fade-out and any audible join cannot be judged from the log.
- **Notebook** (`frost_notebook_en`, `autumn_notebook_pt_BR`):
  - E opens straight on the new page: `page=lore_bearer_<g>` in all five runs, on the Memories tab, unread.
  - The page shows the tube drawing (the branch, stem, bone and stone), the title and Ivo's line, all inside the right page in en and pt_BR.
  - There is no detail line. The plan's `_DETAIL` key does not exist in `translations.csv`; this is consistent with the user's "O tubo e uma frase do Ivo" decision.
- **Skip** (`skip_pause_menu`, `skip_returned`):
  - Escape in frame 1 opens the pause menu with Skip scene second. Down then Z skips.
  - The next frame is the garden under the black cover, which clears in ~0.4 s. Ivo is at (3463.2, -512.0), facing -1, as he stood. The returning completes, and `blocked` clears 1.8 s later.
  - The notebook then opens on `lore_bearer_summer`.
- **No replay.** In the summer run, a second SHADOW performance after the fragment plays its pulse normally. The director stays IDLE through the whole pulse plus 8 s, and Ivo is never blocked.

### Notes (not bugs)

- **The SUMMER ember layer is nearly invisible.** Frames 1 and 3 change only 50-120 game px per 0.5 s, as single-art-pixel specks against a busy crater (`summer_frame1_no_caption`). At normal viewing the summer engraving reads as still. The other three seasons' layers show clearly.
- **The life HUD's notes stay drawn over the top bar** during the call and the returning. They hide on the stage, because it is the past. This is by design (`LifeHud` is the last child, over the fade, per `systems/life-benches-death`). It is noted only because it is the one element on the bars.
- The garden is in full colour here, so the call's "world goes grey" is a translucent paper fade over colour (`summer_call_paper_fade`). It reads as a wash, not a desaturation.

### Cannot be judged from frames

The muffle and the song track's entry and 1.5 s fade, input feel (none is asked for), whether the pan speed feels contemplative or busy, and whether ~32 s of engraving with no caption visible holds attention. The last point is moot until the caption bug is fixed.

## Re-run after the caption fix (2026-11-13, 643d9bf0 + the working tree)

`EngravingView` now draws after `Letterbox` and before `Fade`, with its `Paper` only between the bars (commit 643d9bf0, `engraving_view_test.test_the_caption_draws_over_the_bars_and_the_paper_between_them`). The five timelines were run again unchanged, through the plain runner (no probe):

- Every frame's caption shows in the bottom bar, cream on black, one line, centred: FROST en (`fixed_frost_frame1_caption_en`), BLOOM pt_BR (`fixed_bloom_frame1_caption_pt_BR`), AUTUMN pt_BR (`fixed_autumn_frame3_caption_pt_BR`), SUMMER en (`fixed_summer_frame1_caption_en`).
- The bars stay black above and below the paper.
- The rest is as above: the return to the same spot and facing, the Memories page (AUTUMN pt_BR: the bone, "O osso oco", Ivo's line in five lines inside the page), the skip back to the garden.

The SUMMER ember layer is still nearly invisible; that is the art's (single-pixel embers), not the view's.

## Ratings rationale

- fun 0: a non-interactive story beat, so not applicable.
- fluidity 4 (after the fix; 3 before): every hand-off ran in order on 7/7 runs: wait, call, travel, engraving, travel back, returning, notebook page, skip, and no replay. The return point and facing were exact, and the timings match the plan to 0.1 s. Before the fix the fragment's text never reached the player.
- aesthetics 4 (after the fix; 3 before): the engravings and season inks are strong, the dithered dissolves and clear look good, and the captions read. The summer ink layer barely shows.

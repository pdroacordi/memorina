---
id: playtests/2026-10-10-camera-on-falls
type: playtest
title: Camera on falls - revision 6 shows the landing 0.20-0.29 s ahead in same-region drops with no stop on room swaps, no step over 27 px outside a region cut, and no void, band or dip beyond HEAD's
status: active
build: d3ae19e + uncommitted camera.gd (00:20:24, revision 6), game.gd (23:39:58); revisions 2-5 kept below
area_tested: "Falls across floor seams: orchard_counterweights -> orchard_mill_town, woods_deep -> woods_root_caves, lake_fishing_village well -> lake_well, village_square well -> caldera_cistern; landings on floors 96 px above a seam (woods_canopy ledge, village_square floor)"
tags: [camera, fall-lead, rooms, seams, region-cut, void, feel, world-05]
related: [bugs/the-fall-lead-collapses-at-a-same-region-glide-swap, bugs/walking-off-a-ledge-above-a-same-region-seam-drops-the-frame-in-one-step, bugs/the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room, bugs/the-fall-lead-jumps-the-frame-into-a-room-the-body-already-touches-below, bugs/the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over, bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below, bugs/the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing, bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame, playtests/2026-10-09-traversal-woods-lake]
created: 2026-10-10
updated: 2026-10-11
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-10-camera-on-falls/01_counterweights_drop_old_vs_new.png
  - screenshots/2026-10-10-camera-on-falls/02_fishing_well_one_frame_jump_and_void.png
  - screenshots/2026-10-10-camera-on-falls/03_square_well_one_frame_jump_and_void.png
  - screenshots/2026-10-10-camera-on-falls/04_rev3_walk_off_one_frame_drop.png
---

> Revision 7 (2026-10-11, after the final review, not re-measured here): the ground cap uses the nearer hit while standing or rising (both sides only while descending) with rays from 2 px above the feet; the fall reach is measured from the frame without shake; a region cut keeps the lead (`snap(true)`); the lead drops to 0 below half a pixel. Covered by `camera_test`, not by these timelines.


## Revision 6 (camera.gd 00:20:24)

**Code.** The ground cap casts two rays at the body's left and right edges and caps only when both hit ground (the deeper hit counts).

**Runs.** Each of the following was run twice, 00:22-00:23, after an `--import` at 00:22:39. The import was needed because a sibling's village `.room` edits were unimported, and the first batch failed to load the village rooms. The square case ran only after it.
- `camfall_a2d_deep_to_caves_dense`
- `camfall_e1d_canopy_ledge_walk_off_dense`
- `camfall_c1d_canopy_ledge_jumps_dense`
- `camfall_c2d_square_jump_dense`

| Case | Landing on screen before touchdown | Largest one-frame step | Still frames while airborne |
|---|---|---|---|
| woods_deep → caves | 0.21 s, 13 fr (= rev 5) | +19 px | **3 frames** at y 244 after the walk-off lean (t 1.63-1.65; rev 5: 8). Those are the frames with Ivo's whole body over the one-way at y 384, moving ≤2 px per frame, 121-125 px above the frame's bottom. Then continuous (+14, +6, +4..+7 per frame). 1 frame at y 564 with the landing in view. |
| canopy ledge walk-off | 0.28-0.29 s, 17 fr | +21 px on the swap | 6 frames at y -780 with the landing in view (accepted) |
| canopy ledge jumps / square floor double jump | always in frame | +11 / +12 px | none. **No dip**: the frame's bottom never passes the room's bottom |

**Result:** `the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over` is **resolved**. The 8-frame rest with the landing out of view is down to the 3 frames the body physically spends over the ledge. Holds with the landing in view are accepted as an engineering judgement (coordinator, 2026-10-11), not a user decision. No dip came back. Every camera bug from this session is now resolved. Ratings are unchanged from revision 5.

## Revision 5 (camera.gd 00:14:34)

**Code.** Revision 4 with the `1 - _glide_weight` fade removed. Instead, the lead moves the frame down at most `fall_lead_follow` (1200 px/s, 20 px per frame), measured from the last step's frame centre and reset by `snap`.

**Runs.** All 13 `camfall_*` timelines, 00:15-00:18. Decisive cases were run twice with the same numbers.
- One square-well run left Ivo balanced on the curb (a known thin-margin walk-off). Its two re-runs fell normally.
- A few logged "+47"-type steps were two frames merged by a harness hitch (Ivo's step doubles too). The table uses single-frame steps only.

| Case | Landing on screen before touchdown (rev 5 / rev 4 / rev 3 / HEAD) | Largest one-frame step | Stop on the room swap | Void | Village-coloured band | Still frames while airborne |
|---|---|---|---|---|---|---|
| 1a counterweights → mill (896 px) | **0.20-0.21 s, 12-13 fr** / 0.14 / 0.22 / 0 | +19 px (Ivo +16.7) | **none** (+19, +18, +18 … through t 2.57) | none | n/a | only at the mill's floor clamp with the landing in view (standard; HEAD too) |
| 1b woods_deep → caves (416 px) | **0.21 s, 13 fr** / 0.18 / 0.21 / 0.11 | +18..+19 px (Ivo +13) | **none** (t 2.09: +10, +12, +11 …) | none | n/a | 8 frames at y 244 after the walk-off lean, **landing not in view** (see below); 2 frames at y 564 with the landing in view (ground cap) |
| 1b' canopy ledge walk-off → deep | **0.29 s, 17 fr** / 0.29 / 0.28 / 0.02 | +21 px on the swap (Ivo +9.6) | the swap falls inside the hold below | none | n/a | 6 frames at y -780 (t 1.82-1.91), landing in view: accepted |
| 1c fishing well → lake_well (narrow) | 0.02-0.03 s / 0.02 / 0.03 / 0.02 | +27 px on the glide after the landing (HEAD +27); the swap frames step +20 | none | 53 x 181 px during the glide (HEAD 60 x 180) | n/a | none |
| 2 square well walk-in → cistern | 0.12-0.14 s / 0.15 / 0.14 / 0.03 | +12 px before the cut (= HEAD); the cut is a +290 snap (HEAD +231) | n/a (region cut) | corner ≤ 42 x 61 px (= HEAD) | **70 px** (≤ 126; HEAD 129) | none |
| 2 square well spawn | 0.02 s / 0.01 / 0.02 / 0.01 | +12 px (= HEAD) | n/a | 66 x 40 px (= HEAD) | 40 px (= HEAD) | none |
| 3 landings above a seam (canopy, square) | always in frame | +11 / +12 px | n/a | none | 0 | none. **No dip** (frame bottom never past the room's bottom) |

**Bugs:**

| Bug | Status | Why |
|---|---|---|
| `the-fall-lead-collapses-at-a-same-region-glide-swap` | **resolved** | No stop on either swap. The landing is back to 0.20-0.21 s ahead. |
| `the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room` | **still fixed** | Steps of +20 per frame at the swap; largest +27, as HEAD. |
| `the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over` | **kept open** | The coordinator's 2026-10-11 rule closes it only if no hold happens with the landing out of view. One does, in woods_deep → caves: the frame rests 8 frames (t 1.63-1.72) after the walk-off lean, while Ivo drifts 1.5-3.3 px per frame, 127 → 110 px above the frame's bottom. The ground-cap ray hits the one-way at y 384 that he drifts past. HEAD holds the frame still there too, with the feet down to 3 px from the edge, so this is not a tracking loss. The bug entry gives a fix and the option to accept it. |
| `the-fall-lead-shows-the-void-beside-a-narrower-room-below`, `the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing`, `walking-off-a-ledge-above-a-same-region-seam-drops-the-frame-in-one-step` | still resolved | Void and band are at HEAD's size or smaller; no dip; walk-off eases at ≤13 px per frame. |

**Ratings, revision 5:**
- **Fun 3** (inferred): the landing shows 0.20-0.29 s before touchdown in same-region drops (HEAD 0-0.11 s). Whether that is enough warning needs a human playtest.
- **Fluidity 4:** in every fall measured, no single-frame step exceeds 27 px outside a region cut, and no room swap stops the frame. What remains is one slow-drift rest well inside the frame, and holds once the landing is visible.
- **Aesthetics 3:** void and band at HEAD's size or smaller. The lake_well glide still shows HEAD's void strip.

## Revision 4 (camera.gd 23:40:24, game.gd 23:39:58)

**Code.** Changes on top of revision 3:
- The lead grows at most at `fall_lead_rise` (720 px/s).
- The lead is multiplied by `1 - _glide_weight`.
- `_fall_reach_for` qualifies the rooms below with a strip one frame-height under the feet.

**Runs.** All 13 `camfall_*` timelines, on 2026-10-11 00:07-00:11, after an `--import` at 00:07:37 that picked up the doors change. Decisive cases were run twice with the same numbers.
- In one fishing-well run Ivo stopped at x 1536, probably a focus loss releasing the held move (a known harness quirk). The two re-runs reached the shaft as before.
- The camera files did not change after 23:40:24.

| Case | Landing on screen before touchdown (rev 4 / rev 3 / HEAD) | Largest one-frame camera step | Void | Village-coloured cistern past the seam | Stall |
|---|---|---|---|---|---|
| 1a counterweights → mill (896 px) | 0.14 s, 8 fr / **0.22 s** / 0 | +25 px (Ivo +16.7), on the glide after the swap | none | n/a | Seam crossing smooth (+15..+19 every frame; rev 3 had +5/+26). **Zero frame on the swap (t 2.56)**, then +8..+11 against Ivo's +16.7 for 4 frames. Feet → frame bottom drops 214 → 145 |
| 1b woods_deep → caves (416 px) | 0.18 s, 11 fr / 0.21 s / 0.11 s | +16 px (when the ground cap lets go, Ivo +3.5) | none | n/a | walk-off eased (+8, +13, +13, +6; rev 3 +38). Zero frame on the swap (t 2.09), then the frame trails (+10..+7 against +10..+12) |
| 1b' canopy ledge walk-off → deep one-way | **0.29 s, 17 fr** / 0.28 s / 0.02 s | +21 px on the swap (Ivo +18.8); walk-off eased +10, +13, +13, +11 | none | n/a | **5 frames still at y -780 (t 1.83-1.90)**, landing already in view (rev 3: 3-4 frames) |
| 1c fishing well → lake_well (narrow) | 0.02 s, 1 fr / 0.03 s / 0.02 s | +29 px on the swap (HEAD +27; rev 3 +66) | 53 x 181 px max, during the glide (HEAD 60 x 180) | n/a | none |
| 2 square well walk-in → cistern | 0.15 s, 9 fr / 0.14 s / 0.03 s | +12 px before the cut (= HEAD). The cut is a +290 snap (HEAD +231) | corner ≤ 42 x 61 px (= HEAD) | **70 px** (≤ 126; HEAD 129) | none |
| 2 square well spawn | 0.01 s / 0.02 s / 0.01 s | +12 px (= HEAD) | 66 x 40 px (= HEAD) | 40 px (= HEAD) | none |
| 3 landings above a seam (canopy, square) | always in frame | +11 / +12 px | none | 0 | none. **No dip** (frame bottom never past the room's bottom) |

**Bugs:**

| Bug | Status | Why |
|---|---|---|
| `the-fall-lead-shows-the-void-beside-a-narrower-room-below` (reviewer) | **resolved** | The lead never enters lake_well or the cistern. Void and band are at HEAD's size or smaller. |
| `the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing` (reviewer) | **resolved** | No frame passes the room's bottom on any landing. |
| `walking-off-a-ledge-above-a-same-region-seam-drops-the-frame-in-one-step` | **resolved** | The walk-off now eases at ≤13 px per frame. |
| `the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room` | **resolved** | +29 px at the swap, as HEAD. |
| `the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over` | **still open** | The seam crossing is fixed. The canopy walk-off's 5-frame hold at the ground cap remains. |
| `the-fall-lead-collapses-at-a-same-region-glide-swap` (new, low) | open | The `1 - _glide_weight` factor removes the lead on the swap frame even when the frame was already yielded. This costs the long drop 0.08 s of warning (0.14 s against rev 3's 0.22 s). |

**Feel notes (inferred).** On a walk-off the frame now eases down ~40 px over 4 frames while Ivo has barely started to fall. After the ground cap releases, a +16 px start follows Ivo's +3.5. Both are bounded by the rise rate and read as a deliberate lean, not a jump; a human playtest should confirm.

**Ratings, revision 4:** fun 3 (inferred; the landing shows 0.14-0.29 s ahead against HEAD's 0-0.11 s), fluidity 3 (no step over 29 px outside the region cut, but a stop at same-region swaps and the canopy hold remain), aesthetics 3 (void and band at HEAD's size or smaller).

## Revision 3 (camera.gd and game.gd 23:27:39)

**Code.**
- Game passes two reaches, `set_reach(body_reach, fall_reach)`. The lead yields only into the fall reach (the current room, plus same-region rooms under its floor seam that span the frame).
- The lead's target is `max(fall_view * air, follow_bottom - feet - margin)`.
- The ground cap and the margin-free down swap are unchanged.

**Runs.** All 11 `camfall_*` timelines plus a new walk-off case (`camfall_e1d/e1s_canopy_ledge_walk_off_*`), from 23:28 to 23:33. Decisive cases were run twice with identical numbers.
- One `--import` at 23:33:09, for a sibling's new `door_stairwell.png`. Before it, the two screenshot runs failed to compile the door script; they were re-run after it.
- The camera files did not change after 23:27:39.

| Case | Landing on screen before touchdown (rev 3 / rev 2 / HEAD) | Largest one-frame camera step | Void | Village-coloured cistern past the seam | Stall |
|---|---|---|---|---|---|
| 1a counterweights → mill (896 px) | **0.22 s, 13 fr** / 0.18 s / 0 | +26 px (Ivo +14.2), after one +5 px frame at t 2.29 | none (same-width rooms) | n/a | **none** (rev 2: 2 frames at 0) |
| 1b woods_deep → caves (416 px) | **0.21 s, 13 fr** / 0.16 s / 0.11 s | **+38 px at walk-off** (Ivo +0.3), t 1.47; after it ≤ +22 | none | n/a | none |
| 1b' canopy ledge walk-off → deep one-way (new) | **0.28 s, 17 fr** / - / 0.02 s | **+38 px at walk-off**, t 1.29 | none | n/a | frame held 3 frames at y -780 (t 1.81-1.88) before the swap; the landing is already in view |
| 1c fishing well → lake_well (narrow) | 0.03 s, 2 fr / 0.11 s (via the +136 jump) / 0.02 s | **+66 px at the swap** (Ivo +12.9), then 2 frames at 0. Before the swap, body + 8 exactly as HEAD (+22, +11..+13) | Before the swap 85 x 22..70 px, the old body-yield strip. On the swap frame 85 x 136, narrowing as the x glide catches up. HEAD peaks at 60 x 180 during its glide | n/a | 2 frames after the swap step |
| 2 square well walk-in → cistern | 0.14 s, 8 fr / 0.15 s / 0.03 s | +9 px before the cut. The cut itself is a +290 snap (HEAD +231), as a region cut should be | a corner beside the cistern of at most 48 x 52 px before the cut (HEAD: up to 16 x 108 at its later cut) | **70 px max** (limit ≤126; rev 2 164; HEAD 129) | none |
| 2 square well spawn [930, 250] | 0.02 s / 0.07 s / 0.01 s | +12 px (= HEAD) | as HEAD | 40 px (= HEAD) | none |
| 3 canopy ledge jumps; square floor double jump | always in frame | +11 / +12 px (HEAD -17 / +12) | none | 0 | none. **No dip**: the frame never passes the room's bottom |

**Bugs:**
- `the-fall-lead-jumps-the-frame-into-a-room-the-body-already-touches-below`: **resolved** (numbers in its Resolution section).
- `the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over`: **still open, smaller**. No frame stops dead. One +5/+26 hiccup remains at the counterweights, and there is a 3-frame hold after the landing is visible on the canopy walk-off.
- New: `walking-off-a-ledge-above-a-same-region-seam-drops-the-frame-in-one-step` (low). The follow term is full on the first airborne frame. 38 px, reproduced twice in two places (`04_rev3_walk_off_one_frame_drop.png`; the two captures straddle a harness hitch, so they show more than one frame of motion).
- New: `the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room` (low). On the swap frame the lead's yield overrides the glide.

**Ratings, revision 3:**
- **Fun 3** (inferred): the landing appears 0.21-0.28 s before touchdown in same-region drops, against 0-0.11 s on HEAD. This answers the user's report; it still needs a human check.
- **Fluidity 3:** the 72-136 px well jumps are gone. Two smaller one-frame steps remain (+38 at walk-offs, +66 at the lake_well swap) and one +5/+26 hiccup.
- **Aesthetics 3:** the void and the palette band are back to HEAD's size or smaller. The swap frame at lake_well briefly shows a taller void strip.

The sections below record revision 2 (23:15:20) and are kept for comparison.

## What was tested

The user's report (2026-10-10): "when we fall into a new room, the camera takes too long to follow and that is really bad for the player to track where he is going to fall."

**Code under test.** The change was revised twice while this session ran. Every result below is labelled with the code it ran on.
- **Latest (23:15:20; all decisive numbers):**
  - `fall_view` 176 px × `air_axis`, capped at the ground under the feet + 32 px (a ray on the world layer).
  - `FallReach`: below the floor seam, the frame yields only into same-region rooms that span its whole width.
  - `RoomExit`: leaving downward no longer needs `SEAM_MARGIN`.
- **First version (22:56):** the lead grew the touch rect, with no ground cap and no region or width test. It ran on the working tree, and on a scratch copy `orig/` (HEAD export plus the 22:56 diff, re-applied by script) after the tree moved on.
- **Old:** HEAD d3ae19e, exported with `git archive`.

The working tree was never edited.

**Method.**
- Timelines `tools/playtest/scripts/camfall_*.json`.
- The `*_dense` timelines log every 0.016 s and take no screenshots, which gives one `log` per physics frame. Screenshot runs hitched for 0.1-0.14 s on this machine.
- The landing is "on screen" when the landing floor's y is within the 640x360 view around `cam_centre`.
- `APPDATA` was redirected per run. The real save's md5 was unchanged.

| Case | Timeline | Fall |
|---|---|---|
| 1a same region, long | `camfall_a1(d)_counterweights…` | Walk off the counterweights shelf (-5900, -2080) into the shaft: 896 px, terminal 1000 px/s. The seam (-1536) is 352 px above the mill-town floor. |
| 1b same region | `camfall_a2d_deep_to_caves_dense` | woods_deep pocket → shaft → caves well floor (704): 416 px, seam 384. |
| 1c same region, narrow room below | `camfall_d1(d)_fishing_well…` | Jump from the fishing village floor into the well mouth, landing on lake_well's one-way (-1440). lake_well spans only x 1280-1920. |
| 2 region seam (cut) | `camfall_b2d/b2s_well_walk_east…`, `camfall_b1d_well_spawn_dense` | Walk west off the square's east curb (1040, 288) into the well, landing on the cistern beam at 544. Also the old `[930, 250]` spawn, which lands on the beam at 416. |
| 3 landing above a seam | `camfall_c1d_canopy_ledge_jumps_dense`, `camfall_c2d_square_jump_dense` | Single and double jumps on woods_canopy's ledge (y -864, 96 px above woods_deep). A double jump on the square's floor at x 700 (y 288, 96 px above caldera_cistern). |

## Findings

**Per case (latest code; one physics frame = 1/60 s):**

| Case | Landing first on screen before touchdown | Old (HEAD) | Jump / void / dip |
|---|---|---|---|
| 1a counterweights → mill | **0.18 s (11 frames)**. Before that, off screen for ~1.3 s (~78 frames) of the 1.5 s fall. | **0 s.** First seen on the touchdown frame. The frame stands still for 0.2 s with Ivo's feet 8 px from the bottom edge (`01_…`, left). | No void (same-width rooms). A 2-frame stall at the seam, then +28 px (`bugs/the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over`). |
| 1b deep → caves | **0.16 s (10 frames)**. Ivo is never closer than 50 px to the bottom edge. | 0.11 s (7 frames). Feet 3 px from the edge. | The frame starts with a +15 px step from rest, then moves smoothly. No void. |
| 1c fishing well → lake_well | 0.11 s (7 frames), but only through a one-frame jump. | 0.02 s (1 frame) | **+136 px in one frame** when the feet cross the seam. A void strip 88 x 136 px at the frame's right for ~5 frames (`02_…`). |
| 2 square well → cistern (walk-in) | 0.15 s (9 frames). The cut is now at feet 454.9 (body wholly below the square), against 527 before. | 0.03 s (2 frames) | **+87 px in one frame** at feet 388. The cistern shows in the village palette up to 164 px below the seam for ~0.13 s, with void past x 1280 (`03_…`). The cut itself is clean. |
| 2 square well (spawn 930) | 0.07 s | 0.01 s | **+72 px in one frame.** He lands on the beam at 416 and the room stays village_square. Afterwards the frame eases up ~1 px per frame. |
| 3 canopy ledge / square floor | Landing surface always in frame | same | **No dip** on any landing: the frame never passes the room's bottom, and no step exceeds 20 px. The first version dipped 23 px (canopy double jump) and 32 px (square, into the cistern), then eased back over ~0.2 s at 3-4 px per frame with no jump. The ground cap fixes `bugs/the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing` in game. |

**Confirmed bugs** (both reproduced on the 23:11 and 23:15 code, two runs each):
- `bugs/the-fall-lead-jumps-the-frame-into-a-room-the-body-already-touches-below` (medium). FallReach rejects lake_well and the cistern correctly. But the plain body-touch reach admits them once the feet cross the seam, and the camera adds the full lead to whatever reach it has. So `bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below` is not resolved by the revision. It now also arrives as a single-frame jump.
- `bugs/the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over` (low). The in-room follow reaches the room clamp ~25 px before the lead asks to yield.

**Feel notes (inferred from numbers):**
- At terminal speed the frame keeps 184 px below the feet. That equals what an ordinary in-room fall shows (camera centred on Ivo), so in open air the landing always appears ~0.18 s before touchdown. The change makes seams behave like open air. It cannot show more unless `fall_view` grows past the half-screen; a lead of ~250 px would put Ivo in the frame's top third.
- Whether 0.16-0.18 s is enough warning to steer is a question for a human playtest.
- In the same-region glide cases the swap is now invisible: the frame has already yielded, and the glide continues at Ivo's speed. Old: a 0.45 s pan that started while he was already landing.

**Not judged:** camera smoothing quality and latency as felt with real input, and audio. A static 60 Hz `cam_centre` series shows steps and stalls, not how they read on a display.

## Ratings rationale

- **Fun 3** (low confidence, inferred): the user's complaint is answered for same-region drops. The landing used to appear at touchdown or ≤0.11 s before, and now appears 0.16-0.18 s before. Ivo is no longer pinned to the bottom edge. A human playtest must confirm the warning is long enough.
- **Fluidity 2:** two of the three seam types (a narrow room below, a region seam) now jump the frame 72-136 px in one physics frame. The old code tracked those gradually. Same-region drops still stall for 2 frames and lurch 28 px. The landing-above-a-seam case is now clean.
- **Aesthetics 2:** the jumps expose up to 88 x 136 px of void beside lake_well and a void corner beside the cistern. The cistern also shows in the village palette for ~0.13 s, a band larger than before. Same-width shafts look right.

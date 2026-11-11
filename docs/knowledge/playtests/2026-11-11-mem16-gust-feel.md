---
id: playtests/2026-11-11-mem16-gust-feel
type: playtest
title: MEM-16 gust feel - the headwind walk is 18% slower under the brace, a standing slide stops at the lip, walking or jumping off still works, and gust dashes no longer cross the ground; the standing brace strides in place
status: active
build: c3c31ff9 + uncommitted MEM-16 working tree. Two code states - runs to lip5/ctl5 saw the 16:50 code; player.gd, the resolver, locomotion_stats.gd and ivo_locomotion_stats.tres changed at 17:00:29 (the `_lip_held_frame` song fix, `headwind_slow` default 0, Ivo-only 0.25), and every decisive run was repeated on that code. No later change (checked 17:10). Re-check below: player.gd, the resolver and ivo.tscn at 17:14:22, runs 17:20-17:24, no change after (checked 17:25).
area_tested: "threshold_bridge (west deck, east lip, ravine floor), lake_shore"
tags: [air, wind, weather, gust, brace, ledge, memorina, snow, z-order, mem-16]
related: [playtests/2026-11-11-mem05-regional-weather, systems/air, systems/seasonal-art, systems/animation, bugs/a-standing-brace-plays-the-push-walk-cycle-in-place, bugs/a-gust-never-breaks-a-song-played-at-a-downwind-lip, bugs/a-standing-brace-cuts-the-memorina-lower-clip]
created: 2026-11-11
updated: 2026-11-11
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-11-11-mem16-gust-feel/headwind_walk_brace_156px.png
  - screenshots/2026-11-11-mem16-gust-feel/standing_brace_marches_in_place.png
  - screenshots/2026-11-11-mem16-gust-feel/lip_hold_feet_over_void.png
  - screenshots/2026-11-11-mem16-gust-feel/gust_dashes_bridge_overlay.png
  - screenshots/2026-11-11-mem16-gust-feel/gust_dashes_lake_shore_overlay.png
  - screenshots/2026-11-11-mem16-gust-feel/dashes_colour_vs_grey_sky.png
  - screenshots/2026-11-11-mem16-gust-feel/recheck_brace_stand_at_lip_vs_idle.png
  - screenshots/2026-11-11-mem16-gust-feel/recheck_idle_brace_stand_idle_cut.png
  - screenshots/2026-11-11-mem16-gust-feel/recheck_lower_then_brace_stand.png
---

## What was tested

These are windowed runs through a scratch copy of `tools/playtest/scripts/mem05_weather_probe_driver.gd`. The copy also
printed `facing`, the AnimationTree state and, from the third lip run on, `is_still()`, `wants_to_move()`, the Memorina
toggle buffer and every `is_still()` gate. Runs used `WX_MS` 0-50 (per frame or every 50 ms) and a fresh `APPDATA`
each. **Forced** = `WX_MEMORY=1`. Another Godot process ran in parallel throughout, so frame times are noisy. No
measurement here depends on them.

1. `mem05_brace_and_streaks` (memory 0.3): walk east into the peak gust, stand, walk west.
2. `mem05_east_lip_mem1` (**forced**): standing near the east lip with no input. Variants: facing west first (`lip2`),
   drawing and playing FREEZE at the held lip (`lip2`, `lip5`, `lip6`), walking off west with the tailwind (`lip3`) and
   jumping straight up at the lip (`lip4`).
3. `mem05_song_pulse_gust` (natural memory 0.3, then a pulse to 1), and `brk` (**forced**): FREEZE drawn in the calm
   with notes 0.5 s apart through the rise.
4. `w1` (**forced**): walking east into a memory-1 peak.
5. Stationary snow views on the bridge's west deck, the ravine floor and lake_shore: 3 calm frames and 21 peak frames
   0.25 s apart. Every pixel brighter in a gust frame than in the calm frame is painted red on the calm frame.

## Findings

**1. The headwind walk now fights the wind (measured).** Walking east into the 0.3 peak (`air` -66) runs at
**156.8 px/s** on every logged frame, against 192 west with the tailwind. That is exactly 192 x (1 - 0.25 x 66/90),
18.3% slower. The brace clip plays throughout (`headwind_walk_brace_156px.png`). Into a memory-1 peak (`air` -220) the
walk is **92 px/s** (192 x 0.75 - 52 drift). By the same formula it would have been 140 before MEM-16; that figure is
inferred, not measured. So the change also bites hard at high memory: about half speed into a song-woken gust. Whether
18% *feels* like resistance in the hands, or only looks like a slower walk, needs a human with a pad. The lean and the
lower speed now agree, which they did not in MEM-05.

**2. Standing brace: right trigger, wrong clip** (`bugs/a-standing-brace-plays-the-push-walk-cycle-in-place`, low).
- **The trigger matches the spec.** Standing facing east into a gust of 60 px/s or more plays `brace`. With his back
  to the wind (`lip2`, facing west) he stays `idle`, sliding forward at 52 px/s at memory 1. With the Memorina drawn
  he stays `memorina_idle`. When the gust ends (strength ~0.26) he returns to `idle`.
- **The clip is the looping push-walk sheet.** At velocity 0 the legs keep striding (`standing_brace_marches_in_place.png`).
- **At memory 1 the slide reads as a moonwalk.** He strides east while the wind slides him west at 52 px/s. That is
  inferred from the clip and the logged velocity; 0.5 s frames cannot show the cycle.
- **So the slide now has a lean, but not a stagger.** It reads better than MEM-05's idle skate, and it still does not
  read as being pushed back.
- The lower clip, now fixed, is not cut: `brk` plays `memorina_lower` for 0.35 s after the gust breaks the song, then
  `brace` (`bugs/a-standing-brace-cuts-the-memorina-lower-clip`).

**3. The lip holds, and the deliberate ways off still work.**
- **The hold, facing east (forced memory 1).** He slides 7180 → 7136.0 (the lip) in ~1.3 s and stays at exactly 7136.0
  through the full 220 px/s peak, on both code states. The same happens facing west.
- **The pulse gust in `mem05_song_pulse_gust`** parks him at the west deck's lip, x 6720, where in MEM-05 it carried
  him into threshold_fields.
- **What the hold looks like** (`lip_hold_feet_over_void.png`). The stop is on the feet's centre. Braced, only his front
  toe (~11 game px) is on the stone, and the back boot is planted 12-24 px out over the ravine. Idle, after the gust, he
  straddles the corner. It reads as teetering more than as holding his ground (part of the bug above).
- **Walking off on purpose with the tailwind works.** Holding `move_left` at the held lip at the peak, he runs off
  (`run`) at once, flies at -412 px/s (192 + 220) and lands on the ravine floor (y 351.9) 0.85 s later.
- **The air still carries him.** A standing jump at the held lip drifts at -220 px/s and crosses the whole gap
  westward, landing on the west deck at x 6888.

**4. A drawn Memorina still breaks in a strong gust, and no longer survives at a lip.**
- **Mid-deck.** In `brk`, drawn in the calm, the 4th note's frame (t 7.21-7.23, `air` -184 to -187) shows velocity
  -0.3 → -1.5, and then `sequence_failed`. Half shelter makes 187 into ~94, just over the 90 deadzone.
- **Natural memory.** In `mem05_song_pulse_gust`, FREEZE at 0.3 completes (t 4.75). A draw during the pulse-woken
  slide (t 11.0) is refused, and FREEZE in the next calm (t 16.0) completes. The MEM-05 run drew before the slide,
  which this run did not, because the gust arrived ~1 s earlier.
- **At the lip, before the 17:00:29 fix.** In `lip2` the draw was accepted at the held lip in a 220 px/s gust, and all
  six notes sounded. It broke only as the gust fell, when the sheltered drift became a sub-pixel step the lip ray no
  longer caught. Stopped at 7136.5 (`lip5`), the same draw broke at once. The outcome hung on the sub-pixel stop point.
- **At the lip, after the fix.** The draw at the held lip is refused in 3 of 3 runs, the same as mid-deck. The details
  are in `bugs/a-gust-never-breaks-a-song-played-at-a-downwind-lip`, which the reviewer found by reading the code
  while these runs were in progress.

**5. Gust dashes no longer cross the ground** (`gust_dashes_bridge_overlay.png`, `gust_dashes_lake_shore_overlay.png`).
- **No dash crosses solid tiles** in any of the three views (21 peak frames each). They stop flush at the bridge deck,
  the rock stair, the stone block, lake_shore's overhang slab, its floating block and its floor.
- **They still draw over the sky and backdrop** (ravine trees, lake pines) and behind Ivo. A dash that meets a block
  is cut cleanly at the tile edge.
- **The remaining marks inside rock are falling snow.** They are short vertical dotted trails from the ambient layer,
  which MEM-16 did not move and which still draws in front of the ground. It was barely visible in MEM-05 and still is.
- **In the air, the grey sky reads as before:** sparse 6x1 white dashes.
- **New observation: colour skies.** At memory 1 the dashes are pale blue-white on pale blue, and in the lightest band
  near the horizon they nearly vanish (`dashes_colour_vs_grey_sky.png`, top colour, bottom grey). This is not caused by
  the z change. It matters because memory 1 is where the gust can break songs.
- MEM-05's "dashes draw over solid ground" is **fixed**.

**What screenshots cannot show:**
- Whether the 18% slowdown feels like pushing against the wind through the stick, or like lag.
- Whether stopping dead at a lip feels like grip, or like an invisible wall.
- The brace cycle's motion between frames.
- Any sound (none exists yet, MEM-15).
- Camera behaviour during the slide.

## Ratings rationale

- **Fun 3 (low confidence, inferred).** The lip hold removes MEM-05's cheapest punishment, being slid into the ravine
  while idle, without taking away the jump drift that makes the gap a timing beat. The 92 px/s memory-1 headwind could
  feel sluggish. It needs a human.
- **Fluidity 3.** Walk speed and lean now agree. The standing brace's stride in place, and the moonwalk while sliding,
  break that agreement whenever he stands. A parked lip stop is abrupt by design.
- **Aesthetics 3.** Dashes behind the ground are a clear fix. The standing pose reuses a walk cycle, and at the lip it
  plants a boot on air. Colour-sky dashes are faint.

## Re-check 2026-11-11 (17:14 code: `brace_stand`, lip probe under the downwind edge)

Six windowed runs on the 17:14:22 `player.gd`/resolver/`ivo.tscn`, **forced** memory 1, the per-frame probe plus the
sprite texture/frame and `body_rect()`: `rc_east` (no input from x 7180), `rc_west` (tap west at t 2), `rc_song` and
`rc_song_e` (draw at the held lip, facing west and east), `rc_lower` (FREEZE drawn mid-deck at x 6900, broken by the
gust) and `rc_walk` (walk east into the peak, release). A gdUnit run may have been going in parallel. No figure here
depends on frame time.

**1. The stride in place is fixed.** Standing facing the wind now plays `brace_stand` = `ivo_push.png` frame 7, every
logged frame from t 6.60 (air -60.7) to 10.57 (air -60.0), with no other frame. The pose is a deep lunge, arms
forward, head low. It reads as pushing into the wind. Sliding west at 52 px/s in that held lunge reads as a skid, not
a moonwalk. Walking into the wind still plays the `brace` cycle, frames 0-8 (`rc_walk`, 92-128 px/s). The clip enters
and leaves once each way per gust: one crossing of 60 px/s each way, no flicker.

**2. Where he stops: the body is on the stone, the braced back boot is not**
(`recheck_brace_stand_at_lip_vs_idle.png`, red line = the lip, world x 7136).
- He stops at x 7147.3, then 7147.0, with `body_rect` 7136.0..7158.0. That is the downwind edge exactly on the lip,
  facing east or west (`rc_east`, `rc_west`, `rc_song*`). Before the change he stopped at 7136.0.
- **Idle** (facing west through the gust, or facing east after it): both boots are on the stone. The back heel sits on
  the corner.
- **`brace_stand` facing east**, the case that plays in every gust at a downwind lip: the front boot is fully on the
  stone. The trailing boot spans window x 392..~410 against the lip at 426, so it is **8-17 game px out over the
  ravine**. The frame's stance is ~45 game px wide against the 22 px body, and the trailing foot is always the
  downwind one. The old ~11 px toe-hold is gone, but the pose still plants one boot on air for the whole gust (3.6 s
  here). So "both boots on stone" holds for idle and not for the brace. Bug reopened.

**3. A draw at the held lip is refused.** Facing west (draw at t 7.98, as `lip6`) and facing east (draws at 8.3 and
9.0): no `memorina_drawn` in any of the three attempts, and the lip hold is unchanged. Mid-deck, a drawn FREEZE still
breaks on the 4th note (`rc_lower`: t 7.20 note at air -190, `sequence_failed` and `memorina_sheathed` at 7.23), as
before.

**4. Transitions** (`recheck_idle_brace_stand_idle_cut.png`, `recheck_lower_then_brace_stand.png`).
- **idle -> `brace_stand` and back are one-frame cuts** from upright to a full lunge. The head drops ~8 game px and the
  feet spread from ~20 to ~45 px in one frame (t 6.5 -> 6.6, and 10.5 -> 10.6). At memory 1 this happens at the start
  and end of every gust. It is not a broken frame, and the 60 px/s threshold does not flicker. In the frames it
  reads as a snap, and whether it pops in motion needs a human. A push frame 5-6 in-between (~0.1 s), or the reverse
  on exit, would soften it. Not filed as a bug: subjective, low.
- **`memorina_lower` -> `brace_stand`:** the lower clip plays all four frames (t 7.23-7.48, 0.35 s), then cuts to the
  lunge at 7.58, the same snap as from idle. The lower is not truncated
  (`bugs/a-standing-brace-cuts-the-memorina-lower-clip` holds). During those 0.35 s he slides west at up to 52 px/s
  upright in the lower pose, a short skate.
- **`brace` (walking) -> `brace_stand` on release** goes from push frame 8 to frame 7, adjacent frames of one sheet,
  so no visible pop. This is inferred from the logged frame indices; it was not viewed.

**Unchanged by the re-check:** ratings stay 3/3/3. Fluidity gains from the end of the moonwalk and loses a little to
the snap. The one-boot-on-air stance keeps aesthetics at 3. Still not judgeable from frames: the snap's feel at 60 fps
and the grip feel of the lip stop.

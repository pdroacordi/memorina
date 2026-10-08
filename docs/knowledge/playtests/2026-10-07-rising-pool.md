---
id: playtests/2026-10-07-rising-pool
type: playtest
title: PZL-09, the rising pool - Chuva lifts rest water and its log to the passage; spring basin and moat unchanged
status: active
build: 0e00313 + uncommitted PZL-09 working tree (see "Build")
area_tested: "trials_solstice/water_trial section 1 (world x 14912), spring trial basin and moat"
tags: [chuva, rain-basin, rising-pool, floater, reach, pzl-09, trials, camera]
related: [architecture/a-pool-rests-below-its-painted-reach, architecture/the-water-level-moves, playtests/2026-09-30-chuva-basin-and-moat, systems/water]
created: 2026-10-07
updated: 2026-10-07
ratings: { fun: 3, fluidity: 3, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-07-rising-pool/rest_from_floor.png
  - screenshots/2026-10-07-rising-pool/rest_pool_peek.png
  - screenshots/2026-10-07-rising-pool/control_from_wall_top.png
  - screenshots/2026-10-07-rising-pool/control_from_log_at_rest.png
  - screenshots/2026-10-07-rising-pool/rise_below_frame_from_wall_top.png
  - screenshots/2026-10-07-rising-pool/log_riding_up.png
  - screenshots/2026-10-07-rising-pool/into_the_passage.png
  - screenshots/2026-10-07-rising-pool/regression_dry_basin.png
  - screenshots/2026-10-07-rising-pool/regression_moat.png
source_files:
  - tools/playtest/scripts/song_rain_rising_pool_control.json
  - tools/playtest/scripts/song_rain_rising_pool.json
  - tools/playtest/scripts/song_rain_rising_pool_from_floor.json
  - tools/playtest/scripts/song_rain_rising_pool_ride_late.json
  - tools/playtest/scripts/song_rain_basin_log.json
  - tools/playtest/scripts/song_rain_freeze_moat.json
---

## Summary

The puzzle works with real input. Without a song, the passage is out of reach from the floor, the
wall top and the log at rest. With Chuva, the pool rises from its rest water, the log carries Ivo
to the wall-top level, and one jump puts him in the passage. The pool reads as rest water that
rises, not a basin filling from nothing, but only when the rest water is on screen. From the two
spots where a player plays the song (the floor and the near wall's top), the camera keeps the rest
water at or below the bottom edge. Slack is very generous: the passage is open for about 17 s per
song. The spring basin and moat behave as they did on 2026-09-30. No bugs filed.

## Build

The build was HEAD `0e00313` plus the uncommitted PZL-09 tree. `--import` ran once at 21:58:25.
Between 21:58:31 and 21:58:53 a sibling agent changed `ice_front.gd` and `water_surface_field.gd`
and added `ice_sheet_shape.gd` (PZL-02, uncommitted). Every run here, including the moat run,
used those files, with no reimport after they changed. No run logged an error.

## What was tested

Spawn (15088, 5970) unless noted. Runs used a redirected `APPDATA`, and the real save's md5 was
unchanged after every run.

- **Control** (`song_rain_rising_pool_control.json`):
  - From the floor, a held jump straight up peaks 146 px above the floor. The passage floor is
    160 px up.
  - Ivo climbs the near wall's top (y 5904). A running jump from it peaks at y 5758, passes the
    passage floor's height at x 15442, 36 px short of the far wall's corner, hits the wall at
    y ~5936 and drops onto the log at rest (top y 6126).
  - From the log at rest, a held jump peaks at y 5981, 141 px below the passage floor.
  - Stepping off the log into the rest water costs 1 HP, sinks him, and respawns him on the floor
    beside the near wall (15190, 6000). He had stood on the 32 px wall top last, so it was not recorded as safe ground.
- **Solution from the wall top** (`song_rain_rising_pool.json`): Chuva is played on the near wall's
  top; the last note is at t 5.6 and the pulse lights at ~7.7.
  - At t 11.0 a running jump lands on the risen log (15478, 5904) at 12.4.
  - A jump at 12.8 lands in the passage (15599, 5840) at 13.6. HP stays 3.
- **Solution from the floor** (`song_rain_rising_pool_from_floor.json`): Chuva is played at
  x 15140. Ivo then climbs the wall top, crosses to the log and enters the passage at t 14.1.
  HP stays 3.
- **Riding and slack** (scratch `ride.json`, `song_rain_rising_pool_ride_late.json`, scratch
  `late_fail.json`): Ivo drops onto the log at rest and plays Chuva on it (allowed; the log at rest
  is still). He then stands still, and the log `log` steps record his y as the level.
  - Jump with right held at log y 5958 (t 29.6, drain): reaches the passage.
  - Jump at log y ~6003 (t 31.2): apex 5857, 17 px short; he lands back on the log.
- **Regression** (`song_rain_basin_log.json`, `song_rain_freeze_moat.json`): both ran unmodified,
  plus a scratch copy of each with only passive `log` steps added.

## Findings

- **Rest water that rises: yes, when it is in frame.**
  - At rest the pool is dark slate grey (region memory 0.35) with a light waterline. The log lies
    on it by the far wall (`rest_pool_peek.png`).
  - Under the pulse the same water turns blue and climbs. The waterline stays a stepped
    pixel line, and Ivo's reflection appears under the log (`log_riding_up.png`).
  - After the pulse it sinks back to the same grey rest.
  - The log's y while he rode (rest 6126-6128, reach 5902-5904) shows the rest stays the floor:
    the water never sinks below it.
  - This matches 03 §6.5 "poças sobem" and "o que boia sobe junto".
- **Camera: the rest water sits at or below the bottom of the frame from both places a player
  plays the song.** This is a level/camera note, not a bug.
  - `GameCamera.framing_offset_y` is -64, so about 135 px of world shows below Ivo's feet.
  - From the floor (y 6000) the frame's bottom is at y ~6135. The rest waterline (~6130) and the
    log's top edge are its last few pixels (`rest_from_floor.png`). The tank looks empty except for
    a sliver of log.
  - From the wall top (y 5904) the frame's bottom is at y ~6039. The rest water is ~90 px below
    the frame. During the song the frame is only rain and air, and the water enters from the
    bottom edge at ~t 10.0, when the rise is about two-thirds done
    (`rise_below_frame_from_wall_top.png`).
  - Holding `look_down` (peek, 96 px) frames the whole pool (`rest_pool_peek.png`), but a
    first-time player has no reason to look. So the first sight of "water at rest that rises"
    depends on the player peeking or falling in.
  - One option: raise the `~` rows two cells (rows 18-19). The log at rest would then top out at
    ~6062. From there a jump peaks at ~5916, still 76 px under the passage, so the control holds.
    The rest water would then be ~70 px inside the frame from the floor. From the wall top it
    would still start below the frame.
  - The architect may prefer a camera hint. This is a design decision; nothing was changed.
- **The log riding up.**
  - The rise from rest to the reach took 3.0 s (t 11.6 to 14.6 in the ride run). That is the
    3 s `fill_time` at memory 1 inside the pulse, with the smoothstep ease-in visible in the
    numbers.
  - The log carried Ivo with no jitter, no slip and no hazard contact. At the reach its top
    stands level with the near wall's top (5903 vs 5904), as authored.
  - While full it bobs 1-2 px on the waves, which reads as floating.
  - Riding up on the log works as a second solution: drop onto it from the wall top, play on it,
    ride up, jump.
- **Slack: about 17 s per song, which is generous.**
  - The passage needs the log at y ≤ ~5986 (the peak is 146 px; the floor is 5840).
  - Rising, the log passes that at ~t 13.4, ~1.8 s after the pulse lights.
  - It holds at the reach until ~26.3 (the 10 s sustain plus the 4 s contraction).
  - It drains at memory 0.35 (~10.7 s, rest to reach) and drops below the threshold at ~30.6.
  - A late jump that falls short lands back on the log, never in the water, and Chuva can be
    replayed from the log. Nothing here punishes a slow player.
  - This is a learning puzzle (base movement, single jump), so it is probably intended. It is
    recorded so the later sections (PZL-03, PZL-06) can be tuned tighter on purpose.
- **Room bounds.**
  - The camera clamps to the room's left (x 14912) and right (15680) edges; the frames confirm
    both.
  - The passage is a dead end four cells deep (end wall cols 22-23), with an open shaft above it
    that no jump reaches. That fits section 1 of a room still being built.
  - The left wall shared with `empty_house` is 224 px tall, beyond a single jump, so the room is
    reached by F10 or its `WaterSpawn`.
  - Falling into the risen water also respawns him on the floor (seen in a mistimed run).
  - Nothing clips at the room's edges.
- **Observation for a human eye, not a finding.** Raindrop dents leave short dithered vertical
  streaks hanging under the waterline. They fade slowly over the grey drain (stacked crops,
  t 17-45). The flat, untouched rest water has none. This is probably the same reflection and
  dent behaviour as the spring basin, but I could not tell from frames whether it is intended.
- **Regression: unchanged** (`regression_dry_basin.png`, `regression_moat.png`).
  - Spring basin: dry at load (the log on the dry floor, Ivo at y 5987). It fills under the rain
    (log 5987 to 5806 by t 9.9). Ivo jumps from the log into the passage (7836, 5808). HP 3.
  - Moat: no water at t 6.4, before the pulse. Full at 9.6. Congelar's ice grows across by 14.8,
    and Ivo walks across on it (y 6007.9, x 8080 to 8598) with HP 3.
  - This matches 2026-09-30, so the reinterpreted `r` (a lone `r` is a dry basin) and the
    reimported maps did not change the spring trial.

## Ratings rationale

- **Fun 3**, inferred. The beat is clear and satisfying in frames: play, watch the water and
  log climb, step off. But the control's failures are obvious from the layout, and the 17 s
  window removes all pressure. A human playtest is needed to say whether the reveal lands when
  the rest water starts out of frame.
- **Fluidity 3**, inferred from timing only. The climb, the jump onto the log and the jump into
  the passage are each single moves that worked first try with ordinary timings. Camera
  smoothing, input latency and the ~2 s wait between the last note and the pulse cannot be
  judged from screenshots.
- **Aesthetics 4.** The grey rest pool, the blue risen pool, the stepped waterline, the
  reflection under the log and the return to grey all read cleanly. One point is off for the
  framing that hides the rest water from where the player plays.

## Follow-up (2026-10-07)

The tank was changed after this run: the rest water is two rows higher (rows 18-19, in frame from
the floor) and the passage one row higher (floor 192 px up), so a late coyote jump from the wall
top cannot reach it. Re-run of `song_rain_rising_pool_from_floor.json`: Ivo is in the passage
(y 5808) at t 17.9 with hp 3. The other timelines were written for the old layout.

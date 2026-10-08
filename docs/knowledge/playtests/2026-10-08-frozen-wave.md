---
id: playtests/2026-10-08-frozen-wave
type: playtest
title: PZL-03, A Onda Parada - Vendaval piles a crest, Congelar pins it into a ramp to the wall top
status: active
build: 52cebe9 + uncommitted PZL-03 working tree (crest bank cap and off-screen step landed mid-session; see "Build")
area_tested: "trials_solstice/water_trial section 2 (world x 15680..16512), autumn trial chasm, a ledge in section 1"
tags: [gale, freeze, wind-crest, ice-ramp, slope, floor-snap, thaw, camera, pzl-03, trials]
related: [architecture/wind-piles-a-bounded-crest, architecture/ice-is-its-own-sheet, bugs/stepping-from-a-bank-onto-ice-is-an-8-px-fall, bugs/wind-piles-water-above-its-own-bank, bugs/a-crest-built-off-screen-springs-in-overshooting, systems/water, systems/air]
created: 2026-10-08
updated: 2026-10-08
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-08-frozen-wave/crest_from_col_27_wall_off_screen.png
  - screenshots/2026-10-08-frozen-wave/crest_from_the_shore_lip.png
  - screenshots/2026-10-08-frozen-wave/walking_up_the_ice_ramp.png
  - screenshots/2026-10-08-frozen-wave/jump_from_the_ramp_top.png
  - screenshots/2026-10-08-frozen-wave/early_congelar_apex_short.png
  - screenshots/2026-10-08-frozen-wave/late_congelar_low_dome.png
  - screenshots/2026-10-08-frozen-wave/thaw_from_the_shore_stack.png
  - screenshots/2026-10-08-frozen-wave/fall_pose_stepping_onto_ice.png
  - screenshots/2026-10-08-frozen-wave/brace_down_the_ramp.png
  - screenshots/2026-10-08-frozen-wave/chasm_crest_capped_at_bank.png
  - screenshots/2026-10-08-frozen-wave/gale_left_tilts_the_tank.png
source_files:
  - tools/playtest/scripts/song_gale_freeze_crest.json
  - tools/playtest/scripts/song_gale_freeze_crest_early.json
  - tools/playtest/scripts/song_freeze_crest_control.json
  - tools/playtest/scripts/song_gale_freeze_crest_ramp_walk.json
  - tools/playtest/scripts/song_gale_crest_life.json
  - tools/playtest/scripts/song_gale_left_crest_over_the_shore.json
---

## Summary

The puzzle works with real input. Vendaval from the shore piles a straight wedge of water
against the wall. Congelar freezes it into a pale ice ramp that Ivo walks up, and one jump from
its top lands on the wall. The control (Congelar alone) and the fastest possible Congelar both
fail, the second by only 8 px. Congelar works anywhere from about +0.5 s to +7 s after Vendaval's
pulse, so the "too early" failure is a band about 0.5 s wide that a human will rarely hit. The
tight timing is elsewhere: the ice thaws from the shore 1.5 s after Congelar's pulse, so Ivo
must step off the bank 0.6-2 s after it. From the play spot (col 27) the wall is out of frame
while the crest builds. One low bug filed: the 8 px step from bank to ice still plays the fall
pose.

## Build

HEAD `52cebe9` plus the uncommitted PZL-03 tree. `--import` ran at 08:16. At 08:28 the
implementer changed `water_body.gd` and `wind_crest.gd` (the crest is capped by its downwind
bank, and it steps off screen). Runs before 08:28: sol1, sol2, early1, the three window
brackets, ctl1, ud1. Every later run used the new code. Early, +7.0 s, the control and the
solution were re-run on it and matched within 0.2 px. Every run used a redirected `APPDATA`, and
the real save's md5 never changed.

## What was tested

Spawn (15792, 5960) (`CrestSpawn`; not x 15104), facing right, Vendaval drawn at t 1.5 (last note
4.1, pulse ~5.7, "P" below). Notes are 0.4 s apart. Congelar's pulse lights ~4.2 s after its
draw. Each run holds right toward the wall and jumps 0.45 s with right held.

| Congelar drawn | Ice at the wall (stand y, above shore) | Result |
|---|---|---|
| P + 0.1 s (`_early`) | 5927.4 / 72.6 px (re-run 72.8) | apex 5784, 8 px under the top: fail |
| P + 1.0 s | 5915.4 / 84.6 px | lands on the wall top |
| P + 3.8 s (`song_gale_freeze_crest`) | 5879.0 / 121 px (re-run 120.8) | lands, 41 px to spare |
| P + 6.5 s | 5905.4 / 94.6 px | lands |
| P + 7.0 s | 5921.3 / 78.7 px (both builds) | lands, barely |
| P + 7.8 s (sol1) | about 55 px, a rounded dome (from frames) | too low (no jump; fell at the bank first) |
| none, Congelar alone (`control`) | 6008 / -8 px (flat ice) | apex 5864, 88 px short |

Crest height from the wedge slope (sol1, no Congelar yet): about 15 px at P+1.4, 45 at P+4.4, 75 at
P+6.4, 87 at P+7.4 s, about 130 px at the wall near P+11 (from the shore lip). It does not grow
during Congelar's performance freeze. At P+12 the gale contracts and the crest settles: about
80 px at P+14, 40 at P+16 and 15 at P+18, slower once the area is grey.

## Findings

- **The timing between the songs is generous, and the early failure barely exists.** Every
  Congelar from about P+0.5 to P+7 s succeeds. Only a Congelar drawn the moment Vendaval's ring
  ends fails, by 8 px. A player at human pace (0.5 s per note, a breath before drawing) passes
  by "Congelar right away", so design 02 §8.4's "Congelar cedo demais congela uma onda baixa"
  will rarely be seen. The late edge is real and sharp. After P+12 the crest settles while the
  ice front crosses the pool, and a Congelar drawn at P+7.8 s freezes a low dome
  (`late_congelar_low_dome.png`). To make the early failure reachable: a slower `crest_rise_time`,
  a taller wall, or a play spot farther from the pool. These are inferences from the numbers
  above and need a human playtest.
- **The real deadline is stepping onto the ice.** `IceProfile` thaws from the origin 1.5 s after
  the pulse at 48 px/s, and the origin clamps to the shore's column
  (`thaw_from_the_shore_stack.png`).
  - Walking at the pulse, Ivo reaches the bank 0.35 s after it, before the first column is solid.
    He falls in (1 HP), respawns on the shore ~0.8 s later, and still crosses.
  - Walking 0.9 s and 1.5 s after the pulse succeeds. At 1.5 s he steps off at +1.85 s, and the
    8 px drop carries him past the ~17 px already thawed.
  - Walking 3.6 s after (sol1) puts him in the water at the bank, three times.
  - So the window is about 0.6-2 s after the pulse. The thaw takes the ramp's foot about 4 s
    after the pulse and its top about 9 s after. Walking back down from the wall top at +6.3 s,
    he fell through where the thaw front had just passed (x ~16120). This is the "commit forward"
    of design 03 §6.3, but neither the room header nor the design names this second clock for A
    Onda Parada.
- **Ramp locomotion is clean in the numbers.**
  - Walking up, `floor=true` in every 0.05 s sample from the ramp's foot to the wall, with no hop.
    The ramp is about 25° for a 121 px crest. With the gale behind him he climbs at 250-260 px/s
    (wind, not slope).
  - Walking down (`_ramp_walk`), he stays grounded in every sample, in `brace` against the gale
    at 147-190 px/s.
  - Idle on the slope he does not slide: velocity 0 after the gale, a 12 px/s drift while it
    blows. Turning on the slope is smooth.
  - The clips are not slope-aware: the feet do not meet the incline, and the headwind `brace`
    lean read downhill looks like a stumble (`brace_down_the_ramp.png`). That suits a placeholder
    figure. Landing on the slope from a fall was not tested.
- **8 px floor snap elsewhere: no stickiness.** Walking off section 1's 96 px tank wall, he dips
  2 px over the corner while grounded, then falls with normal gravity. The chasm crossing's run,
  jump and landing look as before. The snap does not cover the 8 px step from any bank onto ice
  (`fall_pose_stepping_onto_ice.png`): filed as
  `bugs/stepping-from-a-bank-onto-ice-is-an-8-px-fall`.
- **The camera hides the wall while the crest builds.** From col 27, Ivo sits ~1/3 from the
  left, and the wall (x 16256) is about 35 px beyond the right edge. The crest's top runs off
  frame (`crest_from_col_27_wall_off_screen.png`), so the player cannot compare the wave with the
  wall when deciding when to freeze. From the shore's lip (x 15864, col 29) the whole pool and
  the wall face are in frame, with the wall top just in the corner
  (`crest_from_the_shore_lip.png`), and the crest still reached ~130 px. Suggestion: play spot
  or spawn at col 28-29, re-checked against `test_vendaval_from_the_shore_blows_hard_enough`.
  On the ramp the wall top enters the frame at x ~16050, and it is mid-frame at the jump
  (`jump_from_the_ramp_top.png`). Smoothing and lag cannot be judged from frames.
- **The crest reads as tilted water more than a wave.** It is a straight line with a hard kink at
  its foot, foam ticks under the line, and a peak at the wall (`crest_from_the_shore_lip.png`).
  It reads plausibly as water the wind leans on the wall, but not as a "crista". Frozen, it is a
  clean wedge. An early freeze comes out slightly concave and a late one as a dome
  (the crest moves while the front crosses), and those read more like a frozen wave than the
  ideal straight ramp.
- **Reflection under a tall crest: nothing strange at ~130 px.** The trunks of the background
  trees continue below the sloped surface as faint vertical bands. After Congelar (winter
  colour), the pool under the frozen crest mirrors whole inverted trees, which reads as a
  reflection. One lighter rectangle in that tree column (sol1, t 19.5, rows 205-305 of the crop)
  may be a seam. Unconfirmed, not filed.
- **The ice ramp's look.** It is a flat pale-blue fill from the slope down to the rest line, with
  a lighter 1-2 px top edge and the growing front dithered (`walking_up_the_ice_ramp.png`). It is
  legible and obviously walkable, but plain next to the snow-capped stone; it has no texture or
  highlight down its face.
- **The crest's bank cap works in the engine** (code from 08:28):
  - Vendaval facing left from the shore piles only ~8 px against the 8 px shore bank. Congelar's
    ice there is y 6000 against 6008, and Ivo walks on with no face.
  - The same gale tilts section 1's tank over the divider wall, and its floating log tilts with
    the surface (`gale_left_tilts_the_tank.png`).
  - On the autumn chasm, the crest climbs to the far bank's lip (~35 px against a 40 px bank,
    t 16.8) and settles (`chasm_crest_capped_at_bank.png`).
  - Noted in `bugs/wind-piles-water-above-its-own-bank`. The off-screen overshoot was not
    exercised: some of the pool is on screen from every spot here.

## Ratings rationale

- **Fun 3** (inferred, low confidence): the two-song idea lands. The first success, walking up a
  wave you froze, is the payoff the design promises. But the decision the puzzle is about (when
  to freeze) is forgiving almost everywhere, and the felt pressure comes from the thaw behind the
  player, which the puzzle never explains. The early failure is a near miss at the wall face,
  which reads well when it happens.
- **Fluidity 3**: from logs, the slope walking is clean (no hops, no slide). Against it: the fall
  pose flashes at every bank-to-ice step, the clips do not fit the incline, and the brace lean
  downhill looks like a stumble. Latency and the camera's motion need a human.
- **Aesthetics 3**: the crest and ramp are clear and pixel-clean. The crest is a ruler-straight
  wedge with a hard kink rather than a wave, the ice is a flat fill, and from the intended spot
  the wall is out of frame for the whole build-up.

## Follow-up (2026-10-08)

Changed after this report: `crest_rise_time` 12 -> 15 s, Vendaval at the shore's edge (col 29,
`CrestSpawn`), `FLOOR_SNAP` 12 px. Re-runs at col 29: `song_gale_freeze_crest.json` (Congelar drawn
0.6 s later than in the runs above, P+4.4) lands Ivo on the wall top (y 5776) from 101 px of ice;
`song_gale_freeze_crest_early.json` leaves the ice 56 px above the shore at the wall and the jump
25 px under the wall top. The other timelines were written for col 27 and rise 12.

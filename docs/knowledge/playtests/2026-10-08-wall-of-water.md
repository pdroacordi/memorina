---
id: playtests/2026-10-08-wall-of-water
type: playtest
title: PZL-06, A parede d'água - Redoma raises the pool around its shell, Congelar fixes it as a floor to the high exit
status: active
build: f3143bf + uncommitted PZL-06 working tree (held_discs.gd, water_body.gd and room_map_parser.gd changed at 09:12 mid-session; see "Build")
area_tested: "trials_solstice/water_trial section 3 (world x 16576..17344, ShellSpawn)"
tags: [bell-jar, redoma, freeze, displacement, raised-floor, ice, thaw, respawn, frost-shell, pzl-06, trials]
related: [bugs/a-respawn-inside-a-live-shell-is-crushed-by-its-ring, architecture/the-shell-displaces-water-into-the-reach, architecture/ice-is-its-own-sheet, systems/bell-jar, systems/water, playtests/2026-10-08-frozen-wave]
created: 2026-10-08
updated: 2026-10-08
ratings: { fun: 3, fluidity: 2, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-08-wall-of-water/water_held_against_the_arc.png
  - screenshots/2026-10-08-wall-of-water/jump_from_the_bank_onto_the_raised_floor.png
  - screenshots/2026-10-08-wall-of-water/raised_floor_with_the_shell_up.png
  - screenshots/2026-10-08-wall-of-water/raised_floor_hanging_after_the_shell.png
  - screenshots/2026-10-08-wall-of-water/late_congelar_hump_too_low_at_the_wall.png
  - screenshots/2026-10-08-wall-of-water/inverse_rises_once_the_ice_thaws.png
  - screenshots/2026-10-08-wall-of-water/shell_crushes_ivo_respawned_inside.png
source_files:
  - tools/playtest/scripts/song_bell_jar_freeze_wall.json
  - tools/playtest/scripts/song_bell_jar_freeze_wall_fast.json
  - tools/playtest/scripts/song_bell_jar_freeze_wall_barely.json
  - tools/playtest/scripts/song_bell_jar_freeze_wall_late.json
  - tools/playtest/scripts/song_bell_jar_freeze_wall_early_jump.json
  - tools/playtest/scripts/song_freeze_then_bell_jar_wall.json
  - tools/playtest/scripts/song_bell_jar_wall_control.json
  - tools/playtest/scripts/song_freeze_wall_control.json
  - tools/playtest/scripts/song_rain_shell_pool.json
  - tools/playtest/scripts/song_bell_jar_respawn_inside_shell.json
---

## Summary

The puzzle works with real input. Redoma played at the bank's edge raises the pool 56 px
around the shell in about 1.8 s. Congelar fixes it as a flat floor at y 5943.9, and from it
the exit jump clears the wall top by 39 px. The controls fail as intended: Congelar alone
falls 25 px short, the inverse order leaves the ice at rest, and Chuva leaves the pool at rest.
The deadline is the shell's contraction, not the rise. Congelar must be drawn at most ~3.5 s
after Redoma's pulse, and the water stops rising ~2.6 s after it, so a player who waits for the
water to settle has about 1 s. One high bug: a respawn inside the live shell is crushed by
its ring (two HP for one missed jump).

## Build

HEAD `f3143bf` plus the uncommitted PZL-06 tree. `--import` ran at 09:01:04. At 09:12:25
`held_discs.gd`, `water_body.gd` and `room_map_parser.gd` changed (the importer's
`FORMAT_VERSION` did not, so the imported room stands). On the earlier code: the recon, the
Congelar sweep (6.0, 7.5, 8.5, 9.0, 9.3) and the first peek run. Everything else ran on the
09:12 code: the controls, the inverse, Chuva, the failure runs, and re-runs of 7.5, 9.0, 9.6
and the peek. The re-runs matched within 1 px (floor 5943.9; apex 5801.7 against 5800.7). Every
run used a redirected `APPDATA`, and the real save's md5 never changed.

## What was tested

Ivo at (16688, 6000), the bank's edge (col 55). Notes 0.4 s apart. Redoma drawn at t 1.5: its
pulse lights at ~5.7, the shell closes at ~6.5, contraction starts at ~15.0 and the shell is gone
at ~19.5 (runner `t`, which runs with world time here). Congelar's pulse lights ~4.2 s after it
is drawn. After Congelar each run steps back to x ~16615, runs right, jumps at the bank's edge
(x ~16704), crosses, and jumps at x ~17155.

| Congelar drawn | Pulse | Floor | Result |
|---|---|---|---|
| 6.0 (`_fast`, the earliest: right after Redoma's ring-out) | 10.3 | flat, 5943.9 to the wall | wall top, apex 5800.7 |
| 7.5 (`song_bell_jar_freeze_wall`, both builds) | 11.8 | flat | wall top, apex 5801 |
| 8.5 | 12.8 | flat to x 17065, 5948.8 at 17120 | wall top, apex 5811 |
| 9.0 (`_barely`, both builds) | 13.3 | dips from x ~17000, ~5967 at 17125 | wall top, clips the corner |
| 9.3 | 13.6 | dips from the arc, ~5980 at the wall | hits the face, perches on the corner 4.5 px under the top |
| 9.6 (`_late`, both builds) | 13.8 | slopes down from the arc, 5987-6003 at the wall | apex 5852-5865: fails |
| none, Congelar alone (`song_freeze_wall_control`) | 5.7 | 6007.9 (rest) | apex 5864.9, 25 px short |

Waterline from the frames (Redoma alone): it starts rising at ~6.5, climbs ~35 px/s, and holds
~59 px over the bank (drawn line; Ivo stands at 56.1) from ~8.3. It falls at ~28 px/s from
~15.0 and is at rest by ~17.4.

## Findings

- **The water against the shell reads well** (`water_held_against_the_arc.png`). The level
  outside rises evenly and stands about two cells above the bank against the curve. A navy band
  and a light rim follow the arc, and the pocket inside is visibly dry. It looks like water
  pressed against glass. Outside the 192 px disc the water is grey, so in colour you see only
  the part next to the shell.
- **Inside the pocket, a flat dark backdrop starts 64 px below the bank** (RGB 67,71,75,
  against grey water's 66,72,82). It reads as a lower waterline inside the shell, so the
  pocket can look half full. It is background art, not water (Ivo falls through it). Cause
  unconfirmed; not filed.
- **The jump onto the floor is comfortable** (`jump_from_the_bank_onto_the_raised_floor.png`).
  - A full jump carries 202 px from takeoff to landing at the floor's height (192 px/s for
    1.05 s). The floor begins where the arc crosses it, x ~16872, so any takeoff from x ≥ ~16670
    lands: the last ~35 px of the bank, or a standing jump from the play spot (lands at x 16900).
  - Takeoff at x 16637 lands in the pocket.
  - Landing is clean (`floor=true` at once, no fall pose). There was no snag crossing the ring
    on the way out in any run that jumped out: `vel.x` stayed 192.
- **The floor with the shell up reads as a frozen surface** (`raised_floor_with_the_shell_up.png`):
  a bright line on navy water, with Ivo's reflection under it. Crossing it is uneventful.
- **Once the shell is gone, the floor is a hairline** (`raised_floor_hanging_after_the_shell.png`,
  peek from the wall top). By about 7 s after Congelar's pulse the water is back at rest. The
  floor then hangs ~60 px over open water as a 2-3 px pale line with no visible thickness or
  support, pale blue on the pale-blue winter backdrop. It does not read as something Ivo just
  stood on.
  - It thaws from the bank at 46-48 px/s after the 1.5 s delay, as designed ("Não precisa").
  - No ice forms along the shell's curve. A fall through the pocket at 2.8 s after the pulse
    went straight through the bowl into water. This matches "Chão elevado".
- **Timing between the songs: about 1 s of slack after the water settles.**
  - An early failure cannot happen: the ~4.2 s from drawing Congelar to its pulse is longer
    than the rise.
  - The late failure is the shell contracting while Congelar's front is still crossing. The
    front catches the level as it falls, so the floor slopes down to the wall
    (`late_congelar_hump_too_low_at_the_wall.png`: a hump, steep at the arc, falling to the wall).
  - A player who watches the water finish rising (~2.6 s after Redoma's pulse) and then plays
    has about 1 s before the floor at the wall is too low. A player who plays Congelar at once
    has ~3 s.
  - The failure shows as a near miss at the wall face, which reads well. Nothing tells the
    player why, because the shell's contraction starts after Congelar is already drawn. Human
    pace (a breath between songs) may land on the edge. That is an inference from these
    numbers.
- **Timing against the thaw (P = Congelar's pulse) is generous.**
  - A standing jump at P+0.25 lands at P+1.3 before the ice there has set, and Ivo falls into
    the raised water.
  - At P+0.8 he lands on ice.
  - The floor's near end thaws at about P+5.0 and the landing area at about P+5.7, so a jump
    up to ~P+4.5 works. That edge is inferred from the measured thaw front, not run.
  - The window is about P+0.6 to P+4.5. Crossing takes 1.6 s, and the far end thaws at ~P+12.
- **Inverse order** (`song_freeze_then_bell_jar_wall`, `inverse_rises_once_the_ice_thaws.png`).
  Congelar at rest, then Redoma at once: the shell cuts its dry pocket under the ice, and the
  level stays at rest while any ice is left. When the last ice thaws (t ~17.9) the shell is still
  up until ~19.2. The pool then rises the full ~59 px in about 1.5 s and falls again. So "Congelar
  then Redoma raises nothing" holds only while the ice lasts. Playing Congelar into that late
  rise is the right order anyway, so the puzzle is not broken. The late surge may surprise.
- **Chuva raises nothing** (`song_rain_shell_pool`): rain falls and splashes on the pool, and the
  waterline stays at rest from t 6 to t 21.
- **Redoma alone, the water falls back.** At t 17.0 it stood ~3 px above the bank top while the
  shell (radius ~64) still covered the bank's corner. No unsupported water was seen above the
  bank at 0.25 s sampling: the plan's risk did not show.
- **Bug: after a fall out through the bowl, the shell treats Ivo as an outsider.** The
  respawn puts him back inside, and the contracting ring shoves him through the stone bank
  into the pool (`shell_crushes_ivo_respawned_inside.png`). Every way of failing this puzzle
  while the shell is up triggers it:
  - a short jump into the pocket;
  - a jump made before the ice sets;
  - walking back off the floor's end once the ring has shrunk away from it.

  One mistake costs 2 HP of 3. In one run he also stood on the inside of the bowl and was hurt
  there. Filed as `bugs/a-respawn-inside-a-live-shell-is-crushed-by-its-ring` (high).
- **Camera.** From the play spot, the rising water and the floor's near end are in frame, and
  the exit wall is not. It comes into frame at about x 17000 on the floor. From the wall top the
  pool is below the frame unless Ivo looks down (`look_down` held shows it). Smoothing and lag
  cannot be judged from frames.

## Ratings rationale

- **Fun 3** (inferred, low confidence): the logic is legible. The shell visibly holds the water
  up, freezing it gives a floor, and the exit is one jump. The decision the puzzle tests (play
  the second song before the shell lets go) has a real but short, unexplained deadline once the
  rise is done. The bad case is the failure path: one missed jump costs two HP through the
  shell bug.
- **Fluidity 2**: the solution itself is clean, with no snags, no fall pose and a flat floor. But
  every failure while the shell is up ends with Ivo shoved through solid stone or standing on
  the inside of the ring. This is from logs and frames; input latency and camera feel need a
  human.
- **Aesthetics 3**: the water against the curve and the frozen surface while the shell stands
  read well. Two things are weak: the floor left behind is a near-invisible hairline over open
  water, and the pocket's dark backdrop reads as a second waterline.

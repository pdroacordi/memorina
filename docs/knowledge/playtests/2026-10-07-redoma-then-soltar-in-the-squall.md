---
id: playtests/2026-10-07-redoma-then-soltar-in-the-squall
type: playtest
title: PZL-07 squall - after SquallMemory a gust breaks Soltar and Redoma's shell shelters it (~5 s of slack), but the lowered bridge is a 10 px curb that needs a jump
status: active
build: 26fd68e + uncommitted PZL-07 working tree, two states (see What was tested)
area_tested: "Winter trial puzzle 2 (Inverno Logico 1), trials_winter at world x 0, cols 41-74"
tags: [redoma, bell-jar, soltar, release, wind, squall, drawbridge, trials, pzl-07]
related: [bugs/the-winter-squall-never-breaks-a-song-at-the-trials-memory, bugs/a-lowered-drawbridge-is-a-10-px-curb-on-its-own-bank, bugs/the-winter-trial-tree-layers-end-in-vertical-cuts-over-the-squall-puzzle, systems/air, systems/bell-jar, systems/weight-presence-release, playtests/2026-09-30-redoma-well]
created: 2026-10-07
updated: 2026-10-07
ratings: { fun: 3, fluidity: 3, aesthetics: 2 }
screenshots:
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/old_build_control_a_bridge_falls_without_redoma.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/control_a_gust_breaks_soltar.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/control_b_bridge_stays_up.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/solution_soltar_inside_the_shell.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/solution_bridge_falls.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/solution_braced_at_the_curb.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/curb_at_the_hinge_3x.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/far_bank_right_wall.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/squall_memory_rectangle.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/squall_memory_edge_gradient_2x.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/old_build_far_bank_soltar_misses_hinge.png
  - screenshots/2026-10-07-redoma-then-soltar-in-the-squall/old_build_grey_squall_streaks.png
---

## What was tested

Two states of the uncommitted tree. All `t` values are the runner's unpaused clock.

- **Old build**: before `SquallMemory`; the squall sat in the trials' memory of 0.35.
- **New build**: `SquallMemory` (RECT 352x224 over the squall, strength 1), `WindSpawn`,
  drawbridge `length_cells` 11, reimported.

Every run redirected `APPDATA`, and the real save's md5 was unchanged after each.
`known_songs` [1, 4]. Timelines are in `tools/playtest/scripts/`:

- `song_release_in_squall.json` (Control A, new build): four tries 4 s apart (a sweep of the
  3.2 s gust cycle). Each try walks in from x 1296, releases, draws at once and plays
  Soltar at the fastest gap (0.27 s).
- `song_release_beside_squall.json` (Control B): Soltar at x 1290.
- `song_bell_jar_release_squall.json` (solution):
  1. Redoma at x 1296 (notes t 1.6-3.6).
  2. Walk right 0.78 s, to x 1442 (146 px in).
  3. Soltar (notes 8.2-10.2).
  4. Walk out with right held, pressing jump once a second.
- Scratch runs (not committed):
  - Old build: stand in the squall; the single-try Control A; Control B; the solution with
    no jump, with a jump in a lull and with one in a gust; a shelter probe (Redoma, walk in,
    stand); four tries inside the squall coloured by a first Soltar; the way back from the
    far bank.
  - New build: Soltar 3 s and 4 s later inside the shell.

## Findings

- **Old build: the squall never broke a song.** Ivo drew in a lull at x 1447 and played
  Soltar with `vel (0, 0)` through a gust. The bridge fell with no Redoma
  (`old_build_control_a_bridge_falls_without_redoma.png`). Undrawn in the grey gust he
  drifted at 22.8 px/s (147 px/s of air, 420 x 0.35). The zone's clock ran at 0.35, so the
  gusts lasted ~5 s. This confirms `bugs/the-winter-squall-never-breaks-a-song-at-the-trials-memory`,
  found in review at the same time.
- **New build: the gust breaks the song.** Try 1 drew at the start of a lull (x 1427, t 3.2)
  and got notes 1-2 in. The gust arrived at t ~3.9, the song broke, and the air carried Ivo
  left at 132 px/s to the box's edge (x 1317) (`control_a_gust_breaks_soltar.png`). Tries
  2-4 were released into a gust and could not draw while he slid. The lull in which he can
  draw lasts ~0.7 s, against ~1.6 s for a draw plus six notes at the fastest gap.
  The old-build tries inside a squall coloured by a first Soltar showed the same: two notes,
  then the break.
- **No exploit at the edges.** The box's 24 px falloff lets a drawn Memorina play at
  x ≤ ~1322, which is 326 px from the hinge, beyond Soltar's 312 px reach. Control B at
  x 1290 completes and the bridge stays up (`control_b_bridge_stays_up.png`). At the right
  end, Ivo against the raised plank (x 1638) is 26 px inside the box, in full wind.
- **The shell shelters the performance.** Soltar's six notes at x 1442 ran with `vel (0, 0)`
  while gusts blew outside (`solution_soltar_inside_the_shell.png`). The bridge fell between
  t 12.25 and 12.75 (`solution_bridge_falls.png`).
- **Slack: about 5 s, comfortable.**
  - Late runs: Soltar 3 s later (notes to 13.1) and 4 s later (notes to 14.1, ring-out
    held to ~15.6) both completed.
  - In the 4 s-late run the wind reached him at t ~16.7. The old-build shelter probe saw
    drift from ~15.4. Both are bounded by the gust phase.
  - So a performance ending by ~15.6 is safe at 146 px in. That is ~10 s after Redoma's
    pulse appears (~5.3).
  - The walk in (0.8 s), draw, six notes at 0.4 s and the 1.6 s ring-out take ~5 s. These
    are timeline numbers, not human ones.
- **Walking out into the headwind.**
  - After Soltar the squall is at full strength. Ivo braces (the lean reads well in
    frames) and makes 60 px/s in a gust and 192 px/s in a lull, so 1442 to 1638 takes
    ~2.4 s.
  - A jump pressed in a gust is carried backward first: `vel.x` -146, x 1638 to 1618 in a
    late run. The plank's end at x 1648-1664 is still inside the box.
  - A jump in a lull goes straight onto the bridge. Past x 1664 there is no wind, and he
    runs at 192 px/s to the far bank (~18.2).
  - Felt weight and latency cannot be judged from frames.
- **Bug: the lowered bridge is a 10 px curb.** Ivo walking right stops at x 1638 against the
  plank's end (`solution_braced_at_the_curb.png`, `curb_at_the_hinge_3x.png`). In the
  old-build run without a jump he braced there 3.6 s, then the gusts blew him back to the
  squall's edge. Filed as `bugs/a-lowered-drawbridge-is-a-10-px-curb-on-its-own-bank`.
- **The far bank is a cul-de-sac (old build; the geometry has not changed).** Once the
  bridge rises (~16 s after Soltar), Soltar from the far bank's edge (x 2000) cannot reach
  the hinge (348 px; `old_build_far_bank_soltar_misses_hinge.png`). Walking off drops Ivo
  into the pool, and the hazard returns him to the far bank. The third fall killed him,
  and he respawned at the authored start (no bench in the runner save). In a debug trial
  F10 is the way out. Designer call; not filed.
- **Right side and camera.** The camera stops with the stone wall (cols 73-74) filling the
  last ~64 px, and no void shows past x 2400 (`far_bank_right_wall.png`). During jumps the
  camera rises enough that the bridge sits at the frame's bottom edge (as in PZL-08).
  Ivo against the wall stays in `run` at zero velocity (known, minor).
- **Does the squall read as a natural current?**
  - Old build, grey: barely. There were sparse white dashes and a few small leaves, low
    contrast against the pale sky (`old_build_grey_squall_streaks.png`).
  - New build: `SquallMemory` turns the box into a remembered winter rectangle (blue sky,
    snow trees) in the grey. It is a strong tell of where the wind is, but it is boxy,
    with straight vertical sides (`squall_memory_rectangle.png`).
  - Its side edges render as a smooth ramp: sampled luminance falls monotonically, ~236 to
    184 to 163, and no Bayer pattern shows (`squall_memory_edge_gradient_2x.png`).
    `systems/greyhush` says boundaries are dithered, never gradients. This may be the
    partial-memory haze rather than the boundary dither. Not filed; whoever owns the
    greyhush should look.
  - The streaks and leaves overrun the box's upwind edge by up to a box width. Particles
    emitted across the whole rect travel `size.x` (`wind_zone.gd` `_fit`). So the calm
    ground where Redoma is played shows streaks too: leaves appear left of the remembered
    rectangle in `squall_memory_rectangle.png`.
  - Ivo carried at 132 px/s stays in the `idle` clip, sliding with his feet planted. Logs
    show `state=idle` throughout. A stagger or brace would read better (inferred).
- **Bug: the background tree layers end in vertical cuts** over the whole puzzle (sprite
  extent, not region drift). Filed as
  `bugs/the-winter-trial-tree-layers-end-in-vertical-cuts-over-the-squall-puzzle`.

## Ratings rationale

- **Fun 3 (low confidence, inferred).** On the new build, "the order is the solution" works
  as §8 intends. The wind visibly takes the song away. The shell is a calm pocket in which
  the song survives, with generous slack. The curb at the bridge, and stopping against it
  in a headwind, undercut the payoff. Being swept to the edge after every failed try may
  frustrate or teach; that needs a human.
- **Fluidity 3 (inferred from logs).** The headwind crawl (~2.4 s) is short. A lull lasts
  ~0.7 s, so "draw in the lull" is a timing test the player is not meant to pass, and the
  game says so only by sweeping him away. Latency and camera smoothing are not judged.
- **Aesthetics 2.** These show in most frames:
  - the vertical tree-layer cuts;
  - the rectangular remembered box with gradient edges;
  - the streaks spilling over the calm ground;
  - the plank sitting on the bank.

  The shell inside Soltar's autumn disc, and the brace lean, read well.

## Follow-up (2026-10-07)

The drawbridge curb and the winter trial's background cuts are fixed. Re-run of
`song_bell_jar_release_squall.json`: Ivo walks past the hinge on the floor and ends on the far bank
(x 2326). The far bank stays a dead end once the bridge rises, as the trial's other ends are (F10).

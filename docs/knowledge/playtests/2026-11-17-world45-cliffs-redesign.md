---
id: playtests/2026-11-17-world45-cliffs-redesign
type: playtest
title: WORLD-45 - the redesigned frost_cliffs route (slope, chimney, path under the slab, wall notch, slab)
status: active
build: uncommitted WORLD-45 frost_cliffs.room over a997a5ec. First pass: room 17:41, imported 17:45. Second pass: room 18:01:00, imported 18:01:19. Third pass: room 18:10:33, imported 18:10:44; nothing under scenes/resources/assets/globals changed after either import
area_tested: "frost_cliffs (origin 9600, -1152; 40x48 cells), base kit (owned_items [0], skills []), from the bench (9808, 288) to lighthouse_base; per-jump probes, failure probes, a descent, the secret niche."
tags: [world-45, rooms, frost-edge, level-design, traversal, playtest]
related: [systems/rooms, systems/world, playtests/2026-11-17-world45-cliff-buttresses, playtests/2026-10-09-traversal-opening, playtests/2026-10-14-world35-step1]
created: 2026-11-17
updated: 2026-11-17
ratings: { fun: 3, fluidity: 4, aesthetics: 4 }   # second and third pass; the first pass was 3/3/3
screenshots:
  - screenshots/2026-11-17-world45-cliffs-redesign/ov_low.png
  - screenshots/2026-11-17-world45-cliffs-redesign/ov_mid.png
  - screenshots/2026-11-17-world45-cliffs-redesign/ov_high.png
  - screenshots/2026-11-17-world45-cliffs-redesign/a02_slope_air.png
  - screenshots/2026-11-17-world45-cliffs-redesign/b00_landing_view.png
  - screenshots/2026-11-17-world45-cliffs-redesign/b01_n1.png
  - screenshots/2026-11-17-world45-cliffs-redesign/c03_p6_view_notch.png
  - screenshots/2026-11-17-world45-cliffs-redesign/d00_notch.png
  - screenshots/2026-11-17-world45-cliffs-redesign/e01_slab_exit.png
  - screenshots/2026-11-17-world45-cliffs-redesign/g00_niche.png
  - screenshots/2026-11-17-world45-cliffs-redesign/g01_niche_outside.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p2_ov2_low.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p2_ov2_mid.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p2_ov2_high.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p2_i00_landing_view.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p2_i01_n1.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p2_j03_under_lip.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p2_j04_well.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p2_k01_step_view_slab.png
  - screenshots/2026-11-17-world45-cliffs-redesign/p3_landing_view.png
---

# WORLD-45: the redesigned climb to the lighthouse

The Summary and Findings below are the first pass (17:41). The coordinator's second pass is in
[Second pass](#second-pass-1801).

## Summary

The new route climbs from the bench to lighthouse_base with single jumps in 12 jumps and ~27 s
(`world45_cliffs_climb.json`), and walks back down to frost_shore without a jump. No softlock, no
spot that traps Ivo. The slope, the chimney and the path under the slab now read as one rock mass
with steps cut into it. The top slab's free west end and the 1-row wall notch still read as
floating shelves. Two take-offs are tight: the notch to the slab, and the secret niche, which only
a short tap reaches. Several head bonks happen, all harmless except two that cost a retry.

## What was tested

Timelines in `tools/playtest/scripts/` (all base kit, `owned_items: [0]`, `skills: []`), rewritten for the second
pass's geometry (the first pass's versions are superseded):

- `world45_cliffs_climb.json`: the full climb from the bench with screenshots at each part.
- `world45_cliffs_steps.json`: each jump on its own (teleport, settle, jump with the direction held), traced per
  physics frame, plus take-off sweeps for the landing → step, well → wall step, wall step → slab and the niche.
- `world45_cliffs_probes.json`: walking both ways under the slab's lip, jumping under it, and running jumps at it.
- A scratch descent (slab to frost_shore holding one direction per section) and zoom-0.5 overviews.

Cell coordinates below are frost_cliffs (col, row). World x = 9600 + 32 col, y = -1152 + 32 row.
Ivo's full jump measured 143.7 px; run 192 px/s.

| Part | Floor (feet y) | Cells |
|---|---|---|
| Bench cave | 288 | cols 0-14, stand row 44 |
| Slope S1..S5 | 192, 128, 64, 0, -64 | 15-18, 19-21, 22-24, 25-27, 28-30 |
| Landing | -128 | 31-38 (roof row 27 over cols 15-33: 128 px headroom) |
| Chimney notches | -256, -352 | 37-38 row 28; 34-35 row 25 |
| Path P1..P6 | -448 .. -608 | 30-33, 26-29, 22-25, 18-21, 14-17, 1-13 |
| Wall notch | -736 | 1-3 row 13 |
| Slab | -864 | 8-39, top row 9; exit col 39 rows 5-8 |

## Findings

**The route works, both ways.** Bench to lighthouse_base: 12 single jumps
(cave→S1→S3→S5→landing→N1→N2→P1→P3→P4/P5→P6→notch→slab), `room=lighthouse_base` at t 28.8. Down:
hold left off the slab (drops to the notch), right down the path (falls into the chimney onto N1),
left down the slope into the cave and out to frost_shore. Every fall lands on part of the route
below, so a missed jump costs one or two jumps, never a long backtrack.

**Ground, not platforms (mostly).** From the slope through the path, the rock is one continuous
mass and the steps are cut into it (`ov_low`, `ov_mid`, `a02_slope_air`). The chimney's two
notches are 2-cell, 1-row ledges on the walls; they read as ledges in the rock, small but attached
(`b01_n1`). Two parts still read as floating:
- **The top slab's west end (cols 8-~20, rows 9-11).** A 3-row slab with open air above (rows 1-8)
  and below (rows 12-16). Its only support is the east wall, off screen from every place where you
  see it from below or from the notch (`d00_notch`, `ov_high`). At play zoom it is a long floating
  platform.
- **The wall notch (cols 1-3, row 13).** A 1-row shelf on the west wall with 3 rows of air under it
  (`c03_p6_view_notch`, `ov_high`). It reads like the old floating ledges.

**Variety: low to moderate.** Both stair sections are perfectly regular: five 3-cell treads with
2-row risers, then five 4-cell treads with 1-row risers (`ov_mid`). A held jump clears two slope
steps at once (rise 143.7 vs 128), so the slope plays as 4 identical jumps, and the path as 3-4
identical hops. The chimney is the only part that asks for a different move (straight up, then
steer). The cobblestone fill (the frost_edge tileset) also makes the rock read as masonry, the
same in every part; that is the tileset, not this layout.

**Head bonks** (all measured from traces):
- S5 → landing, full jump: 6 px into the landing roof (row 27) at x ~10635. Harmless, he lands.
- Landing → N1 from cols 33-35: 8-10 px into N2's underside (row 25 cols 34-35). Harmless, lands on N1.
- **The natural landing spot is under the low roof.** A held jump from S5's middle (x 10507) lands
  at x 10656 (col 33). A jump there bonks at 74 px rise (roof row 27). The player has to walk ~2
  cells east before the N1 jump. Mild, but it is the first moment of the climb that fails without
  explanation.
- **Landing → N1 from right under N1 (x ≥ ~10768, col 36) with right held:** bonks N1's own
  underside (it is 1 row thick, open below at rows 29-31) after 47 px and falls back. Working
  window with right held from take-off: x 10670..10755 (~85 px). A straight jump from col 36 with a
  steer after 0.3 s also works.
- P5 → P6: bonks the slab's underside (row 11, y -768) at x ~9992. Harmless.
- P6 → notch from cols 8-13 (under the slab): bonks and falls back. Take-off works from cols 4-7
  (x 9745-9840 tried) only.

**Precision.**
- **Notch → slab is the tightest jump on the route.** Standing take-off with right held works only
  from x ≥ 9700 (the notch's east ~38 px, 1.2 of its 3 cells); x 9690 lands back on P6. A straight
  jump steered at +0.3 s fails, and so does a 0.25 s press from the edge. A run-up from the wall
  works with ≥ 0.3 s of running. The climb timeline took off at 9702.8: 3 px inside the window. It
  is a standard edge jump (and coyote time helps), but it is the one jump a player will miss more
  than once. A miss lands on P6 (one jump to retry).
- **The secret niche (cols 9-12, rows 38-39) is only reachable with a short tap.** The niche is 64
  px tall under the rock (row 37), so a jump from S1 must rise 64-74 px. Results: a 0.08-0.10 s tap
  with left held works from x 10095-10130 (S1's west ~50 px); a 0.12-0.14 s press works only from
  x 10095; any held jump, and any take-off further east, bonks or falls back into the cave. The
  header's "one jump from the slope's first step" holds only as a short hop from its west end. For
  a secret that may be acceptable, but a player who tries it with a normal jump will conclude the
  opening is decorative. Once inside, the marker shows (`g00_niche`); from S1 the opening reads as
  a dark alcove in the rock with a faint crack hint (`g01_niche_outside`).
- All other jumps (the slope, chimney, path, P6 → notch) have wide windows: rise margins 15.7 px on
  the 4-row jumps (the landing → N1, P6 → notch, notch → slab), much more on the rest.

**Camera shows the next step.** In every frame the next ledge is on screen: S1 from the bench,
both chimney notches from the landing (`b00_landing_view`), P1 from N2, the notch and the slab from
P6 (`c03_p6_view_notch`), the slab top from the notch (`d00_notch`). The camera stays clamped to
the room (1280x1536), so the chimney's east wall is the frame's edge.

**Exit:** the slab meets the lighthouse_base brick at col 39 with a rock column behind the opening
(`e01_slab_exit`); the art changes from cobble to brick at the seam, as before.

**Bugs filed:** none. Nothing here is broken; every finding is a layout or feel note.

## Ratings rationale

- **Fun 3** (inferred from frames and timing, needs a human run): the climb is short and safe, the
  chimney is a nice change of rhythm, but the two stair sections are uniform and the hardest jump
  is a plain edge jump.
- **Fluidity 3:** no softlock, every miss is cheap, the descent flows. The landing under the low
  roof and the N1 underside both stop a natural input without telling why.
- **Aesthetics 3:** the slope, chimney and path read as rock, which answers most of the user's
  complaint, but the slab's free end and the 1-row wall notch still read as floating shelves, the
  very thing the user asked to remove. Static frames only; no judgement of camera motion or feel.

## Second pass (18:01)

The coordinator's changes after the first pass:
- the slab's west end turns down into a lip (cols 6-7, rows 12-14);
- the path passes under the lip (rows 15-16) into a west chimney (cols 1-5);
- the wall notch is a rock step (cols 1-3, rows 13-16), and N1 a rock step from the floor (cols 37-38, top 28);
- N2 is a 2-row corbel (cols 34-35, rows 25-26), and the landing's roof is row 25 over cols 26-33;
- the treads are uneven, with a dip at P3 (cols 22-24, floor row 21).

**The full climb passes:** 12 single jumps, bench to `room=lighthouse_base` at t ~28.6
(`world45_cliffs_climb.json`). It needs a 0.3 s walk east on the landing before the chimney (see #5 below).

**Tight windows re-probed** (feet y, x from per-frame traces):
- **#3 wall step → slab: fixed.** With right held, every take-off on the step works (x 9645, 9670,
  9690, 9705, 9720, 9735). A straight jump steered at +0.3 s also works. Only a 0.2 s press fails.
  The gap is now 2 cells (cols 4-5) instead of 4.
- **#6 N1's underside: fixed.** N1 is a column of rock now. From col 36 (x 10770) with right held, or a
  straight jump steered at +0.3 s, Ivo lands on it.
- **#5 the landing → N1 take-off: still a trap, now from the corbel.** With right held, take-offs from
  x 10720 to the step's face (centre 10773) work; x 10600 (row 25 roof, 6 px), 10640 and 10680 (the
  corbel's underside at y -288, feet capped at -234, 22 px short of N1's -256) fall back. The window is
  ~53 px, narrower than the first pass's ~85 px. The natural landing from the slope still lands in
  the failing zone: a held jump from S5 at x 10520 lands at x 10669, and the next held jump bonks
  the corbel (`p2_i00_landing_view`; the first run of the climb failed exactly here). The cause is
  the corbel's second row (row 26, cols 34-35). A one-row corbel (underside y -320) would cap the
  rise at ~138 px, enough for N1 from cols 33-35 (the first pass showed that), and the landing west
  of col 34 would still be roof-capped.
- **Well → wall step:** works from the well (cols 4-5, x 9739-9781; tried 9745 and 9770). Holding
  left pins Ivo against the step's face at x 9739, so "run into the step and jump" works without
  aiming. From x 9790 the body overlaps the lip, so the jump bonks after 10 px.

**The lip does not snag.** Walking under it both ways keeps the full 192 px/s with `floor=true` on
every frame (the gap is 64 px for a 54 px body). A jump under it bonks after 10 px and lands in
place (`p2_j03_under_lip`). A running jump toward the well started from x ≤ ~9850 bonks the same way,
which is harmless. P5 → P6 still bonks the slab's underside at x ~9992, also harmless.

**Niche (cols 9-12, rows 38-39): unchanged.** A 0.10 s tap from x 10100 gets in. A held jump from
x 10100, a 0.14 s press from 10130, and both jumps from S2 (x 10230: 0.45 s and 0.15 s) fail.

**Look:**
- The west step and N1 are now rock columns rising from the floor below. N2 is a block on the mass.
  The uneven treads with the P3 dip break the staircase rhythm (`p2_ov2_mid`, `p2_ov2_low`).
- The slab plus its lip reads as an overhang (an inverted L) rather than a shelf. It is still held
  only by the east wall, which is off frame from the well and the step (`p2_k01_step_view_slab`,
  `p2_ov2_high`). That is acceptable for an overhang, but a column down to P6 (or to the step)
  would close it.
- The camera shows every next step, as before (`p2_j04_well`, `p2_i01_n1`).

**Ratings (second pass): fun 3, fluidity 4, aesthetics 4.**
- Fun stays 3 and is inferred from frames and timing: the route plays the same jumps, a little less
  uniform. It needs a human run.
- Fluidity rises because the hardest jump (#3) is now forgiving and the lip is clean. The landing → N1
  trap (#5) is the one remaining stop with no visible cause.
- Aesthetics rises because only the slab's overhang still hangs; nothing else floats.

No bugs filed: the landing → N1 trap is a layout note.

## Third pass (18:10)

The only change: the corbel is row 25 only (cols 34-35), so its underside is y -320, level with the landing's roof.

- **Landing → N1 with right held:** take-offs from x 10660 to the step's face (10773) land on N1, about 113 px. Before
  this pass the window was 53 px. From x 10600-10640 the jump still bonks the -320 roof after 137.9 px of rise
  (6 px into it, feet 10 px above N1's top) and falls back, because N1 is too far east to reach before he drops. That
  is the landing's west third, cols 31-32, and it fails visibly under a low roof.
- **The natural flow now works:** a held jump from S5 (x 10520) lands at x 10669, and the next held jump lands on N1
  with no walk. A chained run (S5 jump, then a second jump 1.3 s later, right held throughout) also reaches N1.
- **N1 → N2 and corbel → P1 still work:** with left held, and with a +0.3 s steer from x 10720.
- **The full climb passes** with no walk on the landing: bench to `room=lighthouse_base` at t ~28.6
  (`world45_cliffs_climb.json`, updated; `p3_landing_view`).

Ratings unchanged (fun 3 inferred, fluidity 4, aesthetics 4). No more trap on the main line; the slab's overhang and
the tap-only niche remain the open notes.

---
id: playtests/2026-10-11-open-sky-over-open-tops
type: playtest
title: "OpenSky: the woods_pond shelf jump keeps Ivo in frame; the sky band over open tops and the woods_pond / bloom_hollow seam"
status: active
build: 08c891c + uncommitted OpenSky change (worktree agent-aa9e75dcd54c4f832; open_sky.gd 17:40:17, game.gd 17:40:24, backdrop.gd 17:40:56; runs 17:46-17:54; no scene, resource, global or asset file changed after the first run)
area_tested: "spring_woods: woods_pond (pillar -> shelf jump, shelf double jump), the woods_pond / bloom_hollow seam (floor doorway and the wall top over it)"
tags: [camera, rooms, open-top, open-sky, backdrops, spring-woods, seam]
related: [bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame, bugs/a-hop-above-a-neighbours-open-top-drops-it-from-the-camera-reach, bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, playtests/2026-10-11-world25-rework, systems/rooms, systems/backdrops]
created: 2026-10-11
updated: 2026-10-11
ratings: { fun: 3, fluidity: 3, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-11-open-sky-over-open-tops/pillar_before_takeoff.png
  - screenshots/2026-10-11-open-sky-over-open-tops/shelf_jump_apex_ivo_whole_in_sky.png
  - screenshots/2026-10-11-open-sky-over-open-tops/shelf_landing.png
  - screenshots/2026-10-11-open-sky-over-open-tops/east_wall_top_rest_vs_raised.png
  - screenshots/2026-10-11-open-sky-over-open-tops/double_jump_frame_stops_at_80.png
  - screenshots/2026-10-11-open-sky-over-open-tops/seam_wall_top_frame_straddles_seam.png
  - screenshots/2026-10-11-open-sky-over-open-tops/seam_wall_top_hop_ivo_off_left_edge.png
  - screenshots/2026-10-11-open-sky-over-open-tops/seam_drop_west_sky_band_continuous.png
---

## What was tested

The `OpenSky` change was run windowed with `APPDATA` redirected to a scratch folder. The real save's md5 was the same
before and after. "Visible" is the share of Ivo's 22x54 body rect (above the feet) inside the 640x360 view around
`cam_centre` (zoom 1), computed from `log` lines every 0.05 s and from per-frame `trace` lines.

| Timeline | What it does |
|---|---|
| `open_sky_pond_shelf_jump.json` (new) | Spawn on the pillar top (-4830, 126). At t 1.5 a full jump (0.45 s) west with left held, onto the shelf. |
| `world25_deep_pond_to_bloom.json` | The full route from the bug: woods_deep -> pond step -> pillar -> shelf -> bloom_hollow. |
| `traverse_woods_lake_rv_n2_pond_shelf_double_jump.json` | A straight-up double jump from the shelf (y 64). |
| `open_sky_seam_floor_crossing.json` (new) | Walk west through the floor doorway at the woods_pond / bloom_hollow seam (x -5760, floor y 288), then a double jump east back through it. |
| `open_sky_seam_wall_top.json` (new) | From the shelf's west end (-5494, 62), a double jump west onto the 2-cell wall top over the seam (x -5792..-5728, top y 0). Then walk across the seam on it, hop, walk back, hop. |
| `open_sky_seam_wall_top_drop_west.json` (new) | The same landing, then walk west off the wall top into bloom_hollow. The room swaps and the camera glides while the frame is still raised into the sky. |

## Findings

**The bug is fixed.** `bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame` (`open_sky_pond_shelf_jump`,
`log` every 0.05 s; jump pressed at t 1.50):

```
t      feet y   head y   view top   visible
1.50    128.0     74.0       0.0     1.00   take-off (pillar_before_takeoff.png at 1.40)
1.65     62.8      8.8       0.0     1.00
1.70     45.2     -8.8     -17.0     1.00   frame starts rising
1.80     16.4    -37.6     -46.0     1.00
1.91     -4.1    -58.1     -66.0     1.00
2.01    -13.8    -67.8     -76.0     1.00
2.11    -15.7    -69.7     -78.0     1.00   apex (shelf_jump_apex_ivo_whole_in_sky.png at 2.10)
2.21    -13.2    -67.2     -75.0     1.00
2.31     -5.6    -59.6     -68.0     1.00
2.40     10.4    -43.6     -52.0     1.00
2.50     36.2    -17.8     -26.0     1.00
2.61     64.0     10.0       0.0     1.00   landed on the shelf (shelf_landing.png at 2.70)
```

- Per-frame trace from 1.60 to 2.65: 63 frames, all visible 1.00. The view top never goes above -77.7 (head -69.7 minus the
  8 px margin). It never reaches the -80 cap on this jump.
- The camera's y step per frame is at most 6.1 px. It never jumps or stalls.
- The full `world25_deep_pond_to_bloom` route gives the same numbers: visible 1.00 at every sample from t 12.8 to 21.8,
  apex view top -77 at t 16.0-16.1. Before the fix, visible was 0.00 from 15.9 to 16.2.
- **The sky band reads as sky** (`shelf_jump_apex_ivo_whole_in_sky.png`).
  - Above world y 0 the backdrop's sky gradient continues unbroken.
  - Row-mean colour across the band (window x 700-1280, rows 0-200 at t 2.05) changes by at most 2.1 per row in the band,
    and by 0.7 at the room's top line (row 154).
  - There is no grey strip, dithered line or edge at y 0.
- **The edge wall in the band** (`east_wall_top_rest_vs_raised.png`). At rest, woods_pond's col-39 wall is cut by the frame
  top. Raised, it ends at y 0 with its grass cap and reads as a pillar top against the sky. That is acceptable. The cap was
  always authored; the frame used to hide it.
- **Double jump from the shelf:** the frame stops at exactly -80 (view top -80.0 from t 1.41 to 3.00). Ivo is out of frame
  (visible 0.00) from 1.80 to 2.90 at a peak of feet -205.6 (`double_jump_frame_stops_at_80.png`). The systems entry
  accepts this ("A double jump still leaves the frame"). There was no fade, no hazard beat (`fade=0.00`, `pmode=0`,
  `transitioning=false`, hp 3), and the room stays woods_pond.
- **The floor doorway at the seam** never shows the sky. The doorway is 4 rows tall (y 160..288), so a jump in it hits the
  wall's underside at y 160 and the view top stays at 0 or below. The walk-through glide is unchanged.
- **The wall top over the seam is reachable.** A double jump from the shelf's west end lands on it first try, at x -5742,
  y 0.
  - Standing there, the frame rises to view top -62. Ivo is whole, and before `OpenSky` he could not be seen at all there.
  - The frame straddles the seam by 35 px with no line in the sky (`seam_wall_top_frame_straddles_seam.png`).
  - The column-to-column colour step across the seam inside the band is 0.3-1.3, against a median of 0.3-0.5, at t 4.35-4.55
    of the drop run, when Ivo is clear of the seam column.
  - The two rooms' halves of the wall's grass cap meet without a visible join.
- **Drop west off the wall top** (`seam_drop_west_sky_band_continuous.png`). The room swaps to bloom_hollow at t 4.71 while
  the view top is -25. The 0.45 s glide carries the raised frame across the seam, and the band shrinks to 0 by t 5.06.
  Visible stays 1.00, and there is no pop in the band across the 24 frames at 0.05 s.
- **New defect, low:** `bugs/a-hop-above-a-neighbours-open-top-drops-it-from-the-camera-reach`.
  - Standing at x -5775.9 (the bloom_hollow half of the wall top; the current room is still woods_pond), a 0.15 s hop drops
    bloom_hollow from the reach once his feet pass y -8.
  - The frame snaps 35 px right in one frame and loses him off its left edge for ~0.85 s (visible 0.00, t 4.85-5.68), then
    snaps 12.5 px back on landing (`seam_wall_top_hop_ivo_off_left_edge.png`).
  - `_reach_for` tests each neighbour with its plain bounds, not its sky. The same hop from x -5744 loses him only through
    the top (a row-0 floor, by design).
- **Feel note:** the frame starts rising at full speed. The y step goes 0, 0, 0, -5.3 px in consecutive frames when his head
  reaches the margin, and it stops the same way on landing (6.1 -> 3.1 -> 0). This is the keep-in-view yield's existing
  behaviour, now visible over an open top. Whether it reads as a lurch needs a human.
- **HUD overlap (minor):** on the wall top over the seam, Ivo stands at the frame's left edge, under the three-note health
  HUD (`seam_wall_top_frame_straddles_seam.png`). The room's left clamp puts him there, as at any room's top-left corner.

What screenshots and logs cannot show: whether the frame's rise feels smooth or abrupt, input latency, and how 8 px of
headroom at the apex feels while steering a landing. Those need a human.

## Ratings rationale

- **Fun 3:** inferred. The required jump no longer blinds the player at the moment of steering, which removes the one real
  frustration on this route. Whether the jump feels good is not visible in frames.
- **Fluidity 3:** the camera numbers are clean (no stalls or jumps over 6.1 px per frame on the shelf jump). The seam-hop
  snap is real but sits on an optional perch. The abrupt start and stop of the rise is an inference from per-frame data and
  is unconfirmed.
- **Aesthetics 4:** the sky band is indistinguishable from the rest of the backdrop's sky, at rest and across a seam. The
  edge walls end in authored caps.

## Harness notes

- A `player_position` whose body is above an open top (outside every room) starts with no current room. No room's contents
  load, and Ivo falls through woods_pond and everything below it, landing 1500 px down in caldera_bait. Spawn inside a room
  and jump up instead.
- In a worktree-isolated session, compound Bash commands (`cd` plus pipes and heredocs) were refused. Write helper scripts
  with the Write tool and call them as plain commands.

## Superseded (2026-10-11, room ring)

The 80 px `OpenSky` measured here was replaced the same day by `RoomRing` (160 px on every side, drawn by the nearest room's
backdrop; `systems/rooms` "Room ring"). The re-runs (pond jump, seam wall-top full and double jump, lane_west → woods_edge cut,
village_mill step to ledge) are recorded in `bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame`.

---
id: playtests/2026-11-11-tech12-room-loading
type: playtest
title: TECH-12 room loading - walks, a fall, a door, a death, hazard respawns and the map show no room, backdrop, prop, tile or grass half-built or popping; every screenshot matches HEAD pixel for pixel except where timing differs; a cold first crossing still costs one 16-20 ms frame on the desktop
status: active
build: d2e9ab8c + uncommitted TECH-12 working tree (room_residency.gd 09:16, game.gd 09:26, dissonance_fx.gd 10:01, backdrop.gd 10:35; --import 11:02; runs 11:04-11:25; no scene, resource, asset, global or playtest file changed after the import). HEAD = git archive of d2e9ab8c, imported in the scratchpad.
area_tested: "Walks: village_square -> village_mill -> village_gate_east; village_lane_west -> woods_edge -> woods_deep (jumping); fall from orchard_counterweights into orchard_mill_town. Door: orchard_mill_town <-> orchard_inn. Death: threshold_wayshrine bench rest, killed by the bridge boar, respawn at the bench. Hazard: woods_deep pit, four respawns. Map opened 0.2 s after a walked seam. Forced dissonance veil and revelation."
tags: [tech-12, performance, room-loading, residency, backdrops, clip, dissonance, regression, playtest]
related: [performance/2026-11-11-tech12-baseline, systems/rooms, systems/backdrops, systems/greyhush, gotchas/showing-a-canvas-item-drops-its-rendering-server-clip, playtests/2026-10-11-room-ring-regression]
created: 2026-11-11
updated: 2026-11-11
ratings: { fun: 0, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-11-11-tech12-room-loading/01_square_to_mill_walk_glide.png
  - screenshots/2026-11-11-tech12-room-loading/02_counterweights_fall_into_mill_town.png
  - screenshots/2026-11-11-tech12-room-loading/03_woods_edge_to_woods_deep_jumps.png
  - screenshots/2026-11-11-tech12-room-loading/04_inn_door_back_to_mill_town_fade_in.png
  - screenshots/2026-11-11-tech12-room-loading/05_death_respawn_main_vs_head.png
  - screenshots/2026-11-11-tech12-room-loading/06_map_opened_0.2s_after_a_seam.png
  - screenshots/2026-11-11-tech12-room-loading/07_forced_dissonance_veil_and_revelation.png
  - screenshots/2026-11-11-tech12-room-loading/08_ab_diff_is_a_one_pixel_camera_offset.png
  - screenshots/2026-11-11-tech12-room-loading/09_lane_west_woods_edge_strip_preexisting.png
source_files:
  - scenes/world/rooms/room_residency.gd
  - scenes/world/rooms/room.gd
  - scenes/world/game.gd
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/memory/dissonance/dissonance_fx.gd
  - tools/playtest/scripts/room_residency_probe_driver.gd
---

## Summary

The staggered builds, the clipped backdrops and the hidden dissonance copy show nothing new on screen. In
every timeline, each screenshot matches HEAD pixel for pixel, except where the two runs differ in timing.
A per-frame probe also checked every drawn frame. No room ever drew while still waiting or pending, and
none was missing while the screen was not black. The walked crossings now cost less than on HEAD
(woods_edge 39.9 -> 16.7 ms). On a first visit, though, the crossing frame still takes 16-20 ms on the
desktop: the frame where Ivo enters builds one more room.

## What was tested

- **Setup.** Godot 4.7.2 console build, windowed, debug, 1280x720, vsync on (180 Hz screen, so a normal
  frame is 5.5 ms). Every run used its own `APPDATA` under the session scratchpad. A headless probe printed
  that folder as `OS.get_user_data_dir()` before each run. The real `settings_debug.cfg` had the same md5
  before and after, and no `*.tres` save appeared.
- **Two trees.** Each timeline ran on the working tree ("main") and on a HEAD export with the same inputs.
  A Pillow diff counted the pixels that differ by more than 20 in each screenshot pair.
- **Probe.** Every run went through `tools/playtest/scripts/room_residency_probe_driver.gd` (new). It is a
  `-s` driver that loads the runner and hooks `RenderingServer.frame_pre_draw`, so it runs after
  `Game._process` has called `build_due` and before the frame draws. For every room it logs:
  - its state: none, waiting, pending (a deferred add not yet in the tree), active or idle;
  - when its `shown_cells()` first meet the drawn view (taken from the root canvas transform);
  - every frame dt over 20 ms.
  
  It flags `VIOLATION` when a waiting or pending room's shown cells meet the view, or when any room that is
  not active has bounds inside the view, while the fade is not opaque.
- **Timelines.** Saved as `tools/playtest/scripts/tech12_*.json`:
  - `tech12_village` (+ `_ns` without screenshots): spawn (1616, 280), hold right 14 s. Crosses x 1920
    (square -> mill) at t ~2.7 and x 3200 (mill -> gate_east) at ~9.4.
  - `tech12_woods2`: spawn (-1400, 280), hold left and jump every 0.9 s. Crosses woods_edge -> woods_deep
    at ~8.2, then falls into the woods_deep pit three times (hazard respawns at t 13.1 and 14.3).
  - `tech12_fall`: spawn (-5900, -2090) in orchard_counterweights, walk off the ledge, land in
    orchard_mill_town at ~2.9.
  - `tech12_inn`: spawn (-6660, -1260), walk left 0.25 s (in reach of the inn door at -6704), Up at 1.45.
    Up again inside at 5.0, then run and jump west across mill_town.
  - `tech12_death`: the bench_rest_and_death route. Rest at the wayshrine bench at 3.0, killed by the
    bridge boar at ~13.8, respawn at the bench. Screenshots every 0.1 s from 10 s to 16 s.
  - `tech12_map`: spawn (1800, 280), walk right across x 1920, open the map at 1.95 (0.2 s after the
    swap). The no-screenshot variants of woods, woods2, fall, inn and death are scratch copies of these.
  - `tech12_diss` with `T12_DISS=1`: forces the dissonance veil at 0.6 (t 2.0), the revelation at 0.8
    (t 3.5) and both off (t 5.0), in the village square.

## What works

- **No half-built frame.** The probe checked about 39,000 drawn frames across 18 runs on main: the walks,
  the fall, the door both ways, the bench rest, the death, four hazard respawns and the map. Its only
  `VIOLATION` predates TECH-12 (Findings, 3). The first village run used an earlier probe that
  mis-flagged spring_trial, so it is not counted.
  - In the seven runs that counted it (`WAITSUM`), a waiting room was still queued at draw time in 9
    frames, 0-3 per run.
    - Seven of those frames were 480-1,880 px from the view.
    - Two came right after the bench rest (death run, t 3.02-3.04): icefall_foot and frost_shore, with
      `gap=0.0`. Their cells only touch the view's edge (view x 7680..8320, the wayshrine's bounds;
      frost_shore starts at 8320), so no pixel of theirs is in the frame. `due` uses the same
      border-exclusive `Rect2.intersects`.
  - The queue drains before the next draw: the room that enters view is built in the crossing frame,
    and the rest one per frame over the next 1-4 frames.
- **Pixel-identical to HEAD.** In every frame where the two runs were at the same moment, at most 672 of
  921,600 pixels differ (falling snow), and usually 130-360:
  - village walk: 72 of 75 frames;
  - map: 18 of 18;
  - fall: from the landing on (t 2.6-7.8);
  - the inn interior and the return to mill_town: every frame from the arrival to the end of the fade-in.
  
  The other frames differ only where the two runs are a frame or a few pixels apart (the jumps diverge, or
  a fade started a few frames later). Frame 08 shows the pattern: a one-pixel camera offset outlining every
  brick. So the backdrop scissor cuts no kept pixel, and no prop, tile layer or grass blade appears late or
  changes at any seam that was crossed.
- **Neighbours come into view complete.**
  - 01: the square -> mill glide, with the mill wheel, bridge and lake in frame before and after the swap.
  - 02: the fall from orchard_counterweights shows the mill_town backdrop under the floor from the first
    frame it is in view (t 2.4).
  - 03: woods_edge -> woods_deep, mid-jump.
- **The door.** The arrival in orchard_inn fades in with the room whole. On the way back, orchard_mill_town
  is woken and five neighbours are built one per frame behind the black (f946-951: 6.8, 17.7, 6.2, 5.3,
  5.8 and 6.0 ms). The fade-in starts the frame after (04). On HEAD the same arrival was one 42.6 ms frame.
- **Death and bench.**
  - The death rebuild runs behind the black: 106 ms (HEAD 146 ms), then three more rooms at 27.6, 7.8 and
    7.5 ms, before the fade-in starts.
  - The respawn frames show the wayshrine whole. Its fade-in starts about 0.1 s later than on HEAD (05:
    at t 14.0, main is still near black while HEAD is half faded in). By 14.4 the two are the same.
  - The bench rest rebuilds icefall_foot and frost_shore at 6.9 and 7.2 ms (HEAD: one 24.9 ms frame).
    Nothing visible changes.
- **The first world build's fade.** On HEAD the 170 ms first frame ate about 0.2 s of the fade-in, so the
  first visible frame was already at 40% alpha. Now the queue drains first, and the whole 0.5 s fade from
  black plays (village: alpha 0.94 at t 0.3 against 0.41 on HEAD). This reads as an improvement, not a
  regression.
- **Hazard respawns.** Four falls into the woods_deep pit. Each sinks, fades, and comes back on the east
  lip (-3181, 288) with the room whole. No room was rebuilt, because the respawn stays in woods_deep.
- **Map.** Opened 0.2 s after a walked swap, it draws over a whole scene (06). The camera's 0.45 s glide
  goes on under it, as before.
- **Dissonance copy.**
  - `DissonanceCopy` is hidden in normal play.
  - It shows with the veil (0.6) and with the revelation (0.8), and hides again at zero.
  - Ivo stays visible under both (07). The copy is what keeps them, per
    `gotchas/screen-texture-copy-scope`.
  - The frames match HEAD (0.1-0.4% differing pixels: snow).
- **Walked-crossing cost against HEAD.** Worst frame dt per crossing, in no-screenshot runs (screenshot
  runs hitch about 37 ms at every capture). First visits in a fresh session:

  | Crossing | HEAD | main (frames after the swap) |
  |---|---|---|
  | village_square -> village_mill | 19.4 / 21.8 / 23.7 | 19.4 / 19.7 (+ 6.5-8.4) |
  | village_mill -> village_gate_east | 26.4 / 28.1 | 15.7 / 16.5 / 18.0 (+ 10.1-12.3) |
  | village_lane_west -> woods_edge | 39.9 | 11.8, 16.7, 14.2 |
  | woods_edge -> woods_deep | 20.5 | 12.8, 9.3 |
  | orchard_counterweights fall -> orchard_mill_town | 26.7 | 20.1, 9.2, 6.4 |
  | orchard_inn door -> orchard_mill_town (behind black) | 42.6 | 6.8 ... 17.7 (5 frames) |

  The first HEAD village figure (19.4) is from the run where the probe could not see HEAD's residency, so
  it lists no builds.

## Findings

No defect found that this change introduced. One measurement note and two older observations:

1. **A cold crossing still costs one 16-20 ms frame on the desktop** (a measurement, not a visual bug;
   not filed).
   - The frame where Ivo enters a room also builds one waiting room: either the one whose cells meet the
     view, or the nearest one (`BUILDS_PER_FRAME`).
   - On a first visit, a large room makes that frame expensive:
     - lake_waterfall_path (960x2080) when entering village_mill: 19.4-19.7 ms;
     - woods_hollow_tree when landing in orchard_mill_town: 20.1 ms;
     - caldera_sun_stair when entering village_gate_east: 15.7-18.0 ms.
   - My dt is the time between `frame_pre_draw`s, with vsync on, so it includes the render and the wait
     for vblank. The baseline's 6.4 / 6.0 ms walk figures came from its own probe, after earlier teleports
     had warmed the tile memo. The two are not the same measure.
   - Scaled by the baseline's "CPU about 2x" for the Iris Xe (an inference, not measured), this frame is
     about 32-40 ms on the notebook. That is over 16.6 ms, and near or over the 33 ms ceiling, on the
     first visit of each crossing in a session.
   - Possible lever, untested: skip the "nearest" extra build in a frame where a room was entered or a
     due room was built. Deciding that belongs to the TECH-12 owner.
2. **Pre-existing, not TECH-12: a strip of woods backdrop in colour at the lane_west / woods_edge seam**
   (09, t 2.0, while Ivo is still in village_lane_west).
   - Between woods_edge's earth column and the lane's stone back wall, a strip about 20 px wide shows the
     woods backdrop at the village's memory (green), above the grass line.
   - Once the region cut happens, it greys with the woods.
   - It is identical on HEAD (320 differing pixels in the whole frame), and it is the hard seam that
     `systems/backdrops` allows where a cut touches ground and a `[back]` wall.
   - Listed so a later pass does not mistake it for a clip regression.

3. **Pre-existing, not TECH-12, and too faint to see: the door's fade starts lifting before the camera
   reaches the interior** (`room_residency_probe_driver` log; no frame shows it).
   - In `tech12_inn_ns` on main (f308-309), going into orchard_inn: the probe found the view still on
     orchard_mill_town for two drawn frames after the swap, with mill_town idle (hidden) and the fade no
     longer opaque.
   - The interior has no neighbour to build, so `_build_neighbours` returns at once and `to_clear` starts
     in the swap frame. The canvas only reaches the interior a frame or two later.
   - At 0.5 s per fade, alpha is still about 0.98 in those frames, so at most about 2% of an empty frame
     shows through.
   - HEAD does the same on the way in (3 frames, f248-250). It also does it on the way back out
     (f798, orchard_inn idle in view), which main no longer does: the return now waits five frames of
     builds behind the black.
   - Not filed: nothing a player can see. A run with a darker clear colour or a longer fade could make it
     visible.

## What screenshots cannot show

- **Feel of the hitches.** dt numbers come from the probe. Whether a 16-20 ms frame on a 180 Hz screen is
  felt, and whether 30-40 ms on the notebook would be, needs a person and the notebook. The notebook
  figures here are scaled, not measured.
- **The editor run** ("Rodando pelo editor") was not tested. Every run was a standalone debug run.
- **Audio.** Nothing was measured. Builds that run behind the black do not touch the music.
- **Long sessions and eviction churn.** Each run is a fresh session of at most 19 s, so eviction and
  revisits were exercised only by the door, the bench rest and the death.
- **Not tested:**
  - a teleport (F10 / a cutscene);
  - a room with a `Foreground` (only spring_trial has one);
  - a creature that wanders past its room;
  - particles outside `PropReach`;
  - the dissonance veil in the real finale (forced here through `DissonanceFx.set_dissonance`).
- **The scissor's GPU saving.** It is invisible in a screenshot. The screenshots only prove that the clip
  cuts no pixel.

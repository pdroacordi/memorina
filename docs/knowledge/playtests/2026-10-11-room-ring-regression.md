---
id: playtests/2026-10-11-room-ring-regression
type: playtest
title: "Room ring regression against main: falls, seams and glides frame for frame match main (landing still 0.20-0.29 s ahead, no new jump or stall); a facing turn slides the frame 6-11 px past a room's side again, and the ring draws a hard 45-degree line between two different backdrops"
status: active
build: 9f55197 + uncommitted room-ring change (worktree agent-aa9e75dcd54c4f832; camera.gd and game.gd 22:08:44, room_ring.gd 22:08:18, backdrop_layer.gdshader and backdrop_math.gd 22:04:31, backdrop.gd 21:59:32; --import 22:26:31; runs 22:26-23:05, no scene, resource, global or asset file changed after the import). Main = git archive of 9f55197.
area_tested: "CORE-07 camfall set (orchard_counterweights -> mill_town, woods_deep -> root_caves, canopy ledge walk-off and jumps, lake_fishing_village well -> lake_well, village_square well -> caldera_cistern); seams: square <-> mill glides, lane_west -> woods_edge cut, wayshrine -> frost_shore cut, frost_cliffs -> lighthouse, leaf_path -> arena, mill_town; open tops: woods_pond pillar and seam wall top, village_mill -> lake_waterfall_path; bell tower turn"
tags: [camera, room-ring, backdrops, seams, glide, region-cut, look-ahead, regression, open-top]
related: [playtests/2026-10-10-camera-on-falls, playtests/2026-10-11-open-sky-over-open-tops, bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds, bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops, bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam, bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame, bugs/a-glide-skips-the-drawn-frame-correction-and-snaps-when-it-ends, systems/rooms, systems/backdrops]
created: 2026-10-11
updated: 2026-10-11
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-11-room-ring-regression/01_counterweights_turn_strip_left_edge.png
  - screenshots/2026-10-11-room-ring-regression/02_bell_tower_turn_strip_left_edge.png
  - screenshots/2026-10-11-room-ring-regression/03_ring_wedge_hard_diagonal_at_region_seams.png
  - screenshots/2026-10-11-room-ring-regression/03b_ring_wedge_whole_frames.png
  - screenshots/2026-10-11-room-ring-regression/04_lake_well_glide_ring_corner.png
  - screenshots/2026-10-11-room-ring-regression/05_ring_tie_line_one_px_hole.png
  - screenshots/2026-10-11-room-ring-regression/06_pond_shelf_jump_main_vs_ring.png
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.gd
  - scenes/world/rooms/room_ring.gd
  - scenes/world/rooms/room_residency.gd
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - scenes/world/environment/backdrop/backdrop_math.gd
---

## What was tested

The same timelines ran in two trees, windowed, each with a fresh redirected `APPDATA` (a headless probe checked
`OS.get_user_data_dir()` was under it before every run; the real `save_debug_1.tres` md5 was the same before and after):
- **main**: a `git archive` of 9f55197 in the scratchpad, imported once (the main checkout has a sibling's uncommitted
  `project.godot` edit, so it was not used);
- **ring**: the worktree `agent-aa9e75dcd54c4f832` with the uncommitted room-ring change.

Every timeline got a trace variant: `"trace": true` from t 0.5 (one line per physics frame: feet, velocity, floor,
`cam_centre`), a `log` every 0.1 s for `room=` and the camera bounds, and no screenshots, so no hitches. Screenshot
variants ran separately for illustration only: screenshot runs hitch, and inputs land on different physics frames, so
two trees' stills at one `t` differ by 1-3 frames and sometimes by a different outcome.

Measured per run, from the trace:
- **Visible**: the share of Ivo's 22x54 body inside the 640x360 view around `cam_centre` (zoom 1).
- **Landing on screen**: frames before touchdown during which the landing floor's y stayed inside the view (as in
  `2026-10-10-camera-on-falls`).
- **Steps**: the camera's move per physics frame.
- **Void**: view area outside every room, and outside every room's 160 px ring (from the region scenes' room bounds).
- **Side overshoot**: frames where the view passes the current room's side bound while Ivo's body is inside the room
  and no swap happened in the last 30 frames.
- **Frame-for-frame comparison**: the ring trace shifted by the frame offset that best matches Ivo's path, then
  `cam - feet` compared per frame.

Timelines (29 trace pairs, 11 screenshot pairs): all 8 `camfall_*` cases (dense and shots variants), the 7 `open_sky_*`
timelines and `ring_mill_step_to_ledge`, `traverse_woods_lake_w7a/w7b/w7c` (square to mill glide, lane_west to woods_edge
cut, mill to square glide), `traverse_opening_j` (cliff top to lighthouse), `traverse_opening_h` (wayshrine to frost_shore
cut, frost_shore to frost_cliffs glide), `traverse_orchards_caldera_o2b/o2c` (mill_town, leaf_path to arena glide), and
`bell_tower_helix_climb` (the turn at the helix head). Decisive camfall cases ran twice in ring.

**Corner crossings could not be played.** A scan of every region scene finds four same-region pairs that meet only at a
corner (the case the change now cuts instead of gliding): frost_cliffs / lighthouse_top (10880, -1152), woods_edge /
woods_root_caves (-2560, 384), woods_root_caves / woods_pond (-4480, 384), orchard_windy_gap / orchard_leaf_path
(-7680, -1536). Every one is sealed by a solid wall or floor on at least one side, or out of jump reach (the cliff top is
352 px below the corner). No route in the current world crosses a corner, so the cut never runs in play. Every swap in
every timeline above was a glide on both trees or a cut on both trees.

## Findings

**Falls (CORE-07): no regression.** Ring matches main frame for frame.

| Case | Landing on screen before touchdown (main / ring) | Largest step (main / ring) | Notes |
|---|---|---|---|
| counterweights -> mill (896 px) | 13 fr, 0.22 s / 13 fr, 0.22 s (2 runs) | +18.4 / +18.1 | ring also drifts 6.3 px left past the room (look-ahead, below) |
| woods_deep -> caves | 13 fr, 0.22 s / 13 fr, 0.22 s (2 runs) | +18.8 / +18.8 | `cam - feet` identical every frame |
| canopy ledge walk-off | 17 fr, 0.28 s / 17 fr, 0.28 s (2 runs) | +20.6 / +20.6 | one main run stalled on the ledge (known thin margin), re-run |
| fishing well -> lake_well | 1 fr / 1 fr (2 runs) | +26.8 / +26.5 | the strip beside the well is drawn now (below) |
| square well walk-in -> cistern (cut) | 9 fr, 0.15 s / 9 fr, 0.15 s (2 runs) | cut +290.5 / +290.5 | one frame before the cut, ring yields 5 px into the cistern (feet 381) |
| square well spawn | 1 fr / 1 fr | +12.4 / +4.0 then +8.4 | ring splits main's one step in two |
| canopy ledge and square floor jumps | always in frame | +10.5 / +10.9 | no dip on either tree: the frame's bottom never passes the room's bottom |

- The square floor double jump (`camfall_c2d`) left Ivo's head out of the top on main (visible min 0.23, 41 frames). On
  ring he stays whole (view 21 px into the ring).
- The village-coloured band over the cistern is unchanged. Apart from the one 5 px frame, `cam - feet` is identical up to
  the cut.

**Seams and glides: no new snap or jump.** Same-region glides start with the same steps on both trees:
- square to mill +62 / +64 px; mill to square -64 / -64;
- leaf_path to arena -62 / -64; frost_shore to frost_cliffs +62 / +64;
- the woods_pond / bloom_hollow floor doorway ±64 both ways.

Region cuts are one-frame cuts on both:
- lane_west to woods_edge -599 / -600 (ring adds a 2.9 px frame after it);
- wayshrine to frost_shore +607 / +605;
- village_mill to lake_waterfall_path (+96, -298) / (+99, -290);
- the open-sky lane_west cut -523 / -527.

The ordered glide (`RoomRing.glide_order`) never visibly reordered an axis in these runs: the lake_well glide moves x
and y together on both trees.

**Open tops: the intended gain is real, and none of it costs a fall or a seam.**
- Pond pillar to shelf: visible 0.00 on main (53 frames under 1.00), 1.00 on ring (`06_pond_shelf_jump_main_vs_ring.png`).
- `o2c` leaf_path: min 0.27 -> 1.00.
- lane_west spawn ledge: Ivo's head was cut at rest on main (0.56); ring frames him at rest 30 px into the ring.
- Seam wall-top runs: Ivo is less than whole in frame for 51-148 frames on ring against 188-369 on main. What remains
  is the double-jump apex past the ring, as designed.

**Regression (low): a facing turn slides the frame 6-11 px past the room's side again.** This is
`bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds`, which the sibling review had already
reopened. The look-ahead write is bounded by `_reach`, which is now the ring. Side overshoot with the body inside the
room and no glide:

| Run | main | ring |
|---|---|---|
| counterweights walk-off (turn left) | none | 64 frames, max 6.3 px |
| bell tower helix head turn | none | 64 frames, max 6.3 px |
| lane_west walk to woods_edge | 1 frame (body yield) | 26 frames, max 11.0 px |
| mill walk to square | 1 frame | 29 frames, max 11.4 px |
| lane_west open-sky jump | none | 26 frames, max 9.5 px |
| woods_pond seam wall-top runs | 0-53 frames (only with his body touching bloom_hollow) | 63-74 frames, max 6.3-7.6 px |

Every other run had no overshoot, or the same 1-3 body-yield frames on both trees.
- In the counterweights shaft the strip past the left wall is the room's own ring backdrop, a flat light grey (110, 110,
  112) where the brick wall should continue. It shows 3-5 game px wide at the frame's left edge for ~1 s
  (`01_counterweights_turn_strip_left_edge.png`).
- In the bell tower it is the tower's grey interior backdrop beside the black void framing
  (`02_bell_tower_turn_strip_left_edge.png`; main is black there).
- Before the lane_west to woods_edge cut, the 11 px strip is woods_edge (another region) shown on lane_west's memory.

**New defect (medium, aesthetic): the ring's tie wedge draws a hard 45-degree line between two different backdrops.**
Filed as `bugs/the-ring-tie-wedge-draws-a-hard-diagonal-between-two-backdrops`. The nearest-room rule uses the
farther-axis distance with ties going to the lower x, so above or below a seam, and at every L-shaped corner, the void is
split on a diagonal. The wedge is not dithered. Where the two rooms share a backdrop set it is invisible, as on the
woods_pond / bloom_hollow seam. Where they differ it is a stark line:
- lane_west / woods_edge seam wall top: woods' grey-teal sky cuts into the village's blue sky up and to the right of the
  seam (`03_ring_wedge_hard_diagonal_at_region_seams.png`, `03b_ring_wedge_whole_frames.png`, left);
- village_mill under lake_waterfall_path, frame risen over the mill: the waterfall path's dark forest against the mill's
  light sky (`03`, `03b`, right);
- the lake_well glide: right of the well's wall, below the fishing village's floor, main showed a flat void strip (59-67 x
  155-181 px). Ring draws it in the same place and size, as the well's cave backdrop below a 45-degree line and the
  village's light fill above it, with a dither triangle on the line (`04_lake_well_glide_ring_corner.png`). The void is
  gone. In its place the well's cave reads as open space behind its outer wall for ~0.3 s.

**Confirmed independently: the 1 px tie-line hole.** `bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam`.
In the seam wall-top full jump the far layer shows as a 1 game px light diagonal from the seam's top, up and to the right,
exactly where that entry predicts (`05_ring_tie_line_one_px_hole.png`, ring j_5_25, cam (-5462, 20)).

**Not a regression, a harness artefact:** two of three ring pond-jump trace runs missed the shelf. In those runs the
timeline's `move_left` release at t 2.5 fell when Ivo was at x -5004 / -5014, not -5017. The screenshot run and main
landed, and the camera cannot change his path.

**What screenshots and traces cannot show:** whether the 6-11 px look-ahead drift is noticed in play (it eases in and out
over ~1 s), whether the diagonal wedge reads as a seam or as scenery while moving, input latency, and how the open-top
framing feels while steering. These need a human.

## Ratings rationale

- **Fun 3** (inferred, unchanged): the landing still shows 0.20-0.29 s before touchdown in same-region drops, and the
  open-top jumps keep Ivo in frame. Whether that is enough warning is still a human question.
- **Fluidity 4:** on every fall, seam and glide measured, camera steps match main within 1-4 px, with no new jump, stall
  or snap. The look-ahead overshoot is a slow 6-11 px drift past a side, not a step, and costs one point.
- **Aesthetics 3:**
  - Gains: the main-path void strips (the lake_well glide) and the cut-off Ivo over open tops are gone.
  - Costs: the ring adds a hard diagonal where two different backdrops meet, a 1 px hole line on same-set seams, and the
    look-ahead strip of backdrop beside walls and interior void.

## Harness notes

- `--script` accepts an absolute path, so trace variants can stay in the scratchpad and neither tree is touched. A
  wrapper that `cd`s into the tree breaks a relative path ("Playtest script not found").
- Trace `t` is the runner's `_process` clock: several physics frames share one `t`, and a hitch shows as a `t` gap. Do
  not drop steps across a `t` gap. Every trace line is one physics frame, and a cut can sit right at the gap.

---
id: playtests/2026-10-10-world07-legacy-tiles
type: playtest
title: WORLD-07 legacy biome on the dual grid - trials, world rooms, seams, a pulse edge and root strands, each compared pixel for pixel with HEAD
status: active
tags: [world-07, dual-grid, tiles, legacy, collision, seams, seasonal-art, roots, aesthetics]
related: [architecture/biome-tilesets, bugs/earth-over-stone-draws-the-boundary-half-a-cell-low, bugs/stone-under-earth-draws-a-seasonal-lip-inside-the-ground, bugs/an-earth-cell-boxed-in-by-stone-grows-a-corner-tuft, bugs/a-rooms-ground-art-hangs-into-the-room-below-at-a-mismatched-seam, bugs/root-bridge-strands-meet-at-a-step]
created: 2026-10-10
updated: 2026-10-10
build: c3a3eaf + uncommitted WORLD-07 tree (re-shoot on the 04:46 corner_mask fix; trial runs 04:13-04:21 before the 04:25 clip_rect edit; world, song and seam runs after it; two trial positions re-run on the later code with no change)
area_tested: "Every trial position and the door trial (inside and out); village_square, the square/mill seam, woods_deep, woods_root_caves, lake_shore, caldera_open_crater, orchard_terraces, orchard_leaf_path, lighthouse_base; a ROOT pulse in the winter trial and a FREEZE pulse in the spring trial; spring trial root bridge"
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
---

## What was tested

- **Before/after method.** `git archive HEAD` was exported to the scratchpad and imported there.
  Every timeline ran on both builds, giving pixel-identical cameras, with diff pixels (>20)
  painted red on the new frame. Diffs outside the ground were particles only.
- **Trials.** 29 positions from x 0 to the door trial interior: spawn on the floor nearest
  y 6000 every ~20 columns, then a look down and a look up.
- **World rooms.**
  - village_square: jump up through the one-way `=`, stand on it, walk off it, walk into the
    stone curb (col 26), jump onto it.
  - Walk across the square/mill seam (x 1920).
  - Look up under the bell tower and in lighthouse_base. Bump into the canopy hole from the
    woods_deep ledge.
  - Stand at: woods_deep pit bank, the root-caves well, lake_shore (walk into the pit), the
    crater platforms and bench, the orchard_terraces bench, the orchard_leaf_path floor.
- **Song pulses.**
  - ROOT (spring) at winter trial x 336: the disc crosses a floor edge and the cave hole.
  - FREEZE (winter) at spring trial x 7568: crosses the steps and the stone pillars.
- **Roots.** `song_root_bridge.json` on both builds.

## Findings

- **Collision unchanged.** Every `log` position matched HEAD to 0.1 px:
  - all 29 trial spawns;
  - the square ledge (lands at y 160, through the one-way);
  - the curb stop (x 822), the seam walk (1966.9) and the bridge crossing (9004.8, 5999.9);
  - the crater, caves, deep and lake positions.

  Feet sit on the drawn walk line everywhere looked at, with no sinking or floating. Walls stop
  him at the same x as before; the new rounded faces are inset at most ~2 px.
- **Bug, medium: stone under earth grows a lip inside the ground**
  (`bugs/stone-under-earth-draws-a-seasonal-lip-inside-the-ground`).
  - Every `#` directly on `S` draws a second grass/leaf/snow line and rounded stone corners one
    cell under the real top.
  - It is very visible on the orchard_terraces pillars, under the orchard_leaf_path slab, in
    woods_deep and in the root caves.
  - 118 cells in 10 rooms.
  - `terraces_and_leaf_path_buried_stone_lip.png`, `woods_deep_and_caves_buried_stone_lip.png`
    (screenshots folder; HEAD left).
- **Bug, low: an earth cell boxed in by stone grows a corner tuft**
  (`bugs/an-earth-cell-boxed-in-by-stone-grows-a-corner-tuft`).
  - Water trial (15520, 6000), `water_trial_enclosed_earth_corner_tuft.png`.
  - 5 corners, all in trials_solstice rooms.
- **Re-shoot after the fix (2026-10-10, 04:46 tree).** `corner_mask` no longer counts a look's corner
  that has an earlier solid look directly above it. I re-ran the affected spots with the same
  HEAD-diff method (`fixed_buried_stone_three_way.png`, `fixed_caves_column_and_tuft_three_way.png`;
  HEAD | first | fixed).

  | Spot | Result |
  |---|---|
  | orchard_terraces pillars | PASS |
  | under the orchard_leaf_path slab | PASS |
  | woods_deep block | PASS |
  | woods_root_caves column | PASS |
  | water trial boxed-in corner (15520, 6000) | FAIL on this tree (tuft unchanged); PASS after the second fix below |

  - No lip and no rounded corners inside the ground, and the boundary is a straight line.
  - Collision: the logged positions are identical to HEAD.
  - The stone-on-earth spots (summer c29, spring c49, the_catch) are unchanged apart from
    particles.
  - Left over: the earth/stone boundary now sits 16 px inside the stone cells (terraces col 36:
    stone from y -1296, not -1312). On an exposed side face, earth art covers half a STONE cell
    (02 §7.1). Filed as `bugs/earth-over-stone-draws-the-boundary-half-a-cell-low`.
- **Tuft fix re-shoot (04:53 tree).** A tile with no air corner now counts every later
  corner for the look. **PASS:**
  - All 5 boxed-in corners (water trial (15520, 6000), (15232, 6192), (15488, 6192); the_catch
    (17760, 5520), (17984, 5520)) show a square earth corner with no tuft
    (`fixed_tuft_five_corners.png`, HEAD | fixed).
  - Collision: the logged positions are identical to HEAD.
  - The summer c29 pillar foot has zero diff pixels against the first run, so the rounded
    feet are unchanged.
- **Stone standing on earth now reads as a block resting on the ground**
  (`stone_on_earth_rounded_foot.png`, `square_curb_and_well_wall.png`).
  - Its bottom corners round off and a dark earth notch shows under them. The grass lip curls
    into the corner beside it.
  - Stone faces against earth gain the dotted outline: the_catch, water trial walls, spring
    col 9.
  - This is the decision's edge-adjacent underlay working as designed, not a defect. It is
    the main visible change in the trials.
- **Same as before, or slightly cleaner.**
  - Outer corners, cave-hole inner corners (rounder now) and pillar and boulder tops.
  - One-way `=` ledges keep their thin strip and stay distinct from the 1-high `SSSS` slabs in
    the crater, which now draw as solid slabs, as the plan says.
  - No half-cell offsets and no gaps at cell edges seen at 2.5x on any diffed frame.
- **Pulse edge.** Inside the ROOT disc the snow lip becomes grass, and inside FREEZE the grass
  becomes snow, on earth and stone. The walk line row, the faces and the cave corner do not move
  across the edge, and the dither zone mixes the two lips pixel by pixel
  (`winter_pulse_edge_outline_still.png`).
- **Room edges.**
  - The square/mill seam is invisible on foot.
  - With the 04:25 `clip_rect` in, the woods_canopy floor ends flat at y -768 seen from
    woods_deep, and lighthouse_base's sky shows no strip at its top seam. That is the
    on-screen check the clip's bug entry asked for.
  - Where two rooms are both solid across a horizontal seam, the lower room still draws a grass
    lip on its top row (root caves top, `root_caves_top_edge.png`). HEAD does the same, so it is
    not a regression.
- **Roots.** The strands meet the new bank corners as before, within ~1 px, with the same
  ~3 px start gap at the near bank (`root_strands_at_the_banks.png`). The known 4 px step at
  the join (`bugs/root-bridge-strands-meet-at-a-step`) is unchanged and still open.
- **Log.** No runtime ERROR or WARNING in 46 runs. The only lines are the exit-time
  leaks (texture RIDs, ObjectDB, "resources still in use"), and HEAD prints the same.

## Ratings rationale

These rate the ground's look only. Movement and collision were checked as numbers, not by
feel; the camera and input are unchanged and were not judged.
- **Aesthetics 3:** the legacy conversion is faithful, and the corners are better than HEAD's.
  On the first tree the buried-lip stripes were an obvious defect; after the fix they are gone.
  Both fixes landed the same day. The rating stays 3 for the half-cell-low boundary.
- **Fun 3 and fluidity 3:** carried over. Nothing about movement changed (positions match HEAD
  to 0.1 px).

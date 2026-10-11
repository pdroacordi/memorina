---
id: architecture/walkable-helix-stair
type: architecture
title: Walkable helix stair - Ivo rides a parametric spiral; REVISED 2026-10-11 - the tower turns around him (projected geometry at art resolution)
status: accepted
tags: [helix, stair, interior, bell-tower, lighthouse, movement-mode, depth, canvas-pass, camera, rotation, perspective, subviewport, projection]
related: [systems/helix-stair, architecture/room-void-outside-the-shell, systems/roots-and-climbing, architecture/roots-join-earth-to-earth, systems/foreground, architecture/secret-false-walls, architecture/props-and-ambient-life, systems/rooms, systems/world, systems/greyhush, systems/animation, systems/backdrops, systems/art-pipeline, architecture/room-reachability-audit, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/physics-parent-before-children-one-frame-lag, gotchas/subviewport-does-not-inherit-default-texture-filter, gotchas/a-tween-runs-after-every-process-so-a-process-mirror-is-a-frame-late, gotchas/glsl-gdscript-math-must-be-duplicated]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/interactables/helix_stair/helix_math.gd
  - scenes/world/interactables/helix_stair/helix_steer.gd
  - scenes/world/interactables/helix_stair/helix_stair.gd
  - scenes/world/interactables/helix_stair/helix_end.gd
  - scenes/characters/components/helix_rider_component.gd
  - scenes/world/interactables/helix_stair/helix_projection.gd
  - scenes/world/interactables/helix_stair/helix_faces.gd
  - scenes/world/interactables/helix_stair/helix_view.gd
  - resources/world/helix/helix_look.gd
  - resources/world/helix/helix_stair_shape.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/climb_component.gd
  - scenes/world/camera.gd
  - scenes/world/memory/canvas_pass.gd
  - scenes/world/rooms/home_village/contents/village_bell_tower.room
---

# Walkable helix stair

> **REVISION ACCEPTED 2026-10-11** (the rotating helix; question 6 answered "Floor across (Recommended)", user, 2026-10-11) and built in the WORLD-26 worktree: the contract is `systems/helix-stair`. The user rejected the first version's look. See "Revision (2026-10-11)" at the end; the Decision below is the first version, built and superseded in its rendering, input and ends.

> **Status: IMPLEMENTED** (2026-10-11, WORLD-26 first run; the contract is `systems/helix-stair`). Deviations from the plan below:
> - **`HelixStair` is a `Node2D`**, not an `Area2D`: its two `HelixEnd` children are the areas, and the root has no shape of its own to detect with.
> - **Darker only.** The far scale shimmered (it changes every frame along a far run), so `far_scale` is 1.0 per answer 4; `DepthLook` keeps the scale code.
> - **Boarding** by a side press needs the press toward the axis; a press held since the last dismount boards nothing until it changes (the ping-pong at the foot otherwise).
> - **Tilt 20, not 56.** At tilt 56 > pitch/TAU (50.9) the feet sank briefly at the right side of every turn and the near and far runs met there in a cusp. `HelixStairShape.problems()` now refuses tilt >= pitch/TAU and a slow-side turn radius under 6 px; at 20 the radii are 39 and 7.5 px (coordinator, 2026-10-11).
> - **The head landing starts at the head.** A rising path comes up past the landing's corner, so the landing cannot reach under the end; `check` sweeps Ivo's capsule and allows 6 px of overlap into a cell below the body's middle.
> - **The reach audit** (TECH-05, merged 2026-10-11) gives `@` a new reach role STAIR; `HelixStair.reach_ends` answers the two feet cells and `ReachAudit` joins them both ways.
> - **Not in this run:** the drawn art and style board, the taller facade, `lighthouse_interior`.

WORLD-26. User, 2026-10-10: "the player goes spinning and it almost looks like an optical illusion". Choice: "Walkable helix (Recommended)". `lighthouse_interior` (design 04 §3.3) reuses it.

## Context

Ivo walks a spiral: in front of the near run, behind the far run (smaller, darker), turning at the sides. Characters draw only in the creature pass, over the whole world composite, so nothing in the root canvas can cover him (`systems/foreground`).

## Options considered

- **Movement.** One-way slopes per run with normal physics: near and far cross on screen, so the body takes the wrong branch at each crossing. Flat switchback ledges under decorative art: no illusion. **A parametric ride** (chosen), as climbing follows a `Climbable`.
- **Occlusion.** Moving Ivo between canvases breaks the creature pass; a depth shader has no precedent. **A `ForegroundPass` twin of the near runs** (chosen, the `SecretWall` pattern).
- **Art.** A procedural shader draws weak pixel art. **Static half-turn sprites stacked by pitch** (chosen): a rising camera makes a static helix seem to turn, as in the reference.

## Decision

**Path** (pure `HelixMath`, `scenes/world/interactables/helix_stair/`). Progress `u` in 0..turns·TAU, `a = u - PI/2`: feet = (cx + hand·R·sin a, base - pitch·u/TAU - tilt·cos a); depth = cos a. `tilt` (the view's ellipse, near drawn higher) lets the near run cross in front of the far one. `turns` is a multiple of 0.5, so both ends sit at a side with depth and tilt 0, on cell tops. Angular speed is constant, `speed / sqrt(R² + (pitch/TAU)²)`, so screen speed slows at the sides and the turn reads as rotation.

**Input** (pure `HelixSteer`). Up ascends, Down descends; left/right move along the run in its screen direction, latched through a turn while held (hold one direction, spin up); vertical wins a diagonal at 0.5. `Player` passes `Vector2(move_axis(), look_direction)`; only `PlayerInput` reads input.

**Ownership.** `HelixStair` (root `Area2D`, legend `@`) owns its art, two `HelixEnd` zones on the climbable layer and `set_rider_depth()` / `clear_rider()`. `HelixRiderComponent` (generic, `components/`, ungated) holds it, finding ends through `ClimbSensor` (`ClimbComponent` ignores non-`Climbable` areas). `Player` judges: `MotionState.STAIR` above `KNOCKBACK`; boards in an end zone on a fresh press into the stair or Up/Down, with `ClimbComponent`'s regrab delay; while riding, jump, roll, attack, doors and the Memorina are refused and their buffers dropped, and a hit does not unseat him. The rider sets `velocity = (feet(u) - position) / delta`, so `move_and_slide` keeps collision (a test proves the swept body is air). Past the foot he steps onto the floor; at the head he waits for the outward press, so a held latch never walks him off the landing. `arrive_at`, `sit`, `respawn` and death release the rider; `_landing.check_landing(on_floor or riding)`.

**Depth.** Far runs: world art, z -15. Near runs: a world copy (z 5) and a `ForegroundPass` twin (`CanvasPass.join_layer`, z -1), hidden while the rider's depth > 0.15, shown again below 0.05; off the stair Ivo stands in the axis plane, behind the near runs. The twin is greyed by the foreground composite like the world copy. Facing follows screen x velocity with a dead zone |cos a| < 0.15: one flip, in profile. `DepthLook` (generic component) receives `near` 0..1 from `Player` (like `AirflowBody.exposure`) and, in its own step after the parent's, writes the Sprite2D's `scale` (feet kept) and `self_modulate` (`flash()` owns `modulate`); no RESET track keys either today. The shade is a value multiply in Ivo's own hues, independent of memory, never touching his clocks; the greyhush desaturates and stops time.

**Camera.** One tall room, no seams on the climb. `air_axis()` is 0 while riding, so neither the air lead nor the fall lead runs. A new optional intent `frame_bias()` (+tilt·cos a, read by `has_method` like `air_axis`) frames the axis height: the frame rises steadily and the helix seems to turn; framing the feet would bob the stair ±tilt.

**Data.** `HelixStairShape` Resource (`resources/world/helix/`): `radius`, `pitch`, `turns`, `tilt`, `speed_scale`, `far_scale`, `far_shade`, `near_art`, `far_art` (art drawn for these numbers: one contract). In the `.room`, `@` on the bottom floor, its cell's bottom-left corner the axis base (an even shaft centres on a grid line); params `shape` (a `.tres` path, like a door's `requires`) and `hand` (1: near run climbs right). A static `HelixStair.check(cell, params, map)` feeds `room_files_test` (ends on floor tops, a landing at the head, swept body clear); for the reach audit it is a two-way edge foot to head. Landings are side ledges; the stair never crosses a floor; the lighthouse's mentor room makes two flights. The bell tower becomes 1x4 in `gen_world_shells.py` (from y 12000 down), its `.room` rewritten by hand. Start at R 128, pitch 320, tilt 56, 3.5 turns: about 20 s at 192 px/s. The double-jump alcove stays above the top landing (design 04 §3.1).

**Art** (contracts in `tools/art/prompts/`, then a style board for approval): `helix_stair_wood` (near: underside and stringer; far: treads, darker; one band, 2x); `bell_tower_shaft`, a seamless vertical wall with warm light slits (`cut_wall.py`, a `BackdropSet` with REPEAT fills); `bell_tower_facade` redrawn taller, rising out of `village_square`'s top edge like the lighthouse base, doorway still 64 px. The user's reference images are never uploaded; contracts describe them in words. Placeholders are baked from `HelixMath`, so tuning precedes art.

**Tests** (mirroring the source path): ends at sides with zero tilt, head height, constant 3D speed, screen x speed 0 at the sides, one facing flip per half-turn, latch held through a turn and reset on release, cover hysteresis, `feet + frame_bias` linear in u. Playtest: hold right from the door to the top.

## Consequences

No user-facing text, so nothing for `tr()`. The stair art is bound to its numbers: retuning means re-cutting it. Cut first if costly: the far scale (non-integer scaling of 2x art may shimmer; keep the shade), front and back turn clips, a stair through a ceiling.

## Answers (2026-10-11)

1. Jump on the stair: "Nothing (Recommended)" (user).
2. The Memorina on a step: refused (orchestrator's call, the plan's proposal; the user was not asked).
3. Height: "4 screens (Recommended)" (user).
4. If the far scale shimmers: darker only (orchestrator's call, the plan's fallback).
5. The lighthouse stair: "Stone and iron (Recommended)" (user).

## Revision (2026-10-11): the rotating helix

User, 2026-10-11, verbatim: "It is ok for a room not to ocuppy 100% ofr the screen width (or some cases, height(. In the case of the tower, for example, the room should be slimmer. In the case of the houses, the wood tiles didn't have to fill the rest of the screen either. It's okay to leave a black space or something like that. And the spiraling is not working quite well, there should be something more 3d like. I've attached here a video to help you understand". The slim shell is `architecture/room-void-outside-the-shell`.

The video (another game's footage; described in words only, never uploaded or copied): a slim round tower on black; a helix of discrete steps drawn as a solid spiral (tread tops light and risers dark on one side, the dark soffit and outer edge a thick band across the front, far runs darker behind); the character stays at about one screen x on the front of the stair and the camera rises with him; the steps shift along the spiral and the wall's light slits drift sideways at speeds set by their depth, so the tower seems to turn around him.

**What no longer holds.** The first version moved Ivo left and right across a static ribbon, so nothing turned. Now Ivo never goes behind anything: the tower turns around him.

### Options considered

- **Rendering.** A 3D SubViewport (Camera3D, meshes built from `HelixMath`): a z-buffer and perspective for free, but a second render pipeline, perspective-mapped textures resampled every frame (the far-scale shimmer, `systems/helix-stair`), and a mesh path outside `tools/art`. A fragment shader ray-casting steps per art pixel: a GLSL copy of the geometry the rider and the check use (`gotchas/glsl-gdscript-math-must-be-duplicated`), hard to test. Precomputed frames: locked to Ivo, the helix is screw-symmetric, so the stair's image depends only on its step phase (32 frames per look; the windmills' baked rotation, `architecture/props-and-ambient-life`); but the ends, the bell, slits and posts are not screw-symmetric and the perspective follows the camera, so runtime drawing is needed anyway. **Projected flat-shaded geometry drawn by `_draw` at art resolution into a SubViewport shown at 2x** (chosen): one GDScript projection for the view, the check and the tests; faces filled from the board's colour ramps, edges and mortar as 1 px lines.
- **Wall and slits.** A wall strip scrolling with rotation and slit sprites placed by angle: under perspective each column is scaled by a factor that changes as the eye moves, so nearest sampling drops a different row set each frame (the far-scale shimmer). **Geometry** (chosen): a polygon edge moves by whole art pixels and a 1 px line never drops out.
- **Projection.** Orthographic with a fixed tilt (the first version): every run shows the same face. **Perspective** (chosen): runs below the eye show treads, runs above show the soffit, the front is wider than the back.
- **Landing.** A side ledge drawn by the view over collision-only cells: needs an invisible-solid legend kind, and a fall into the well leaves the tower's angle undefined (Ivo would fall through drawn treads). **A static plank gallery across the shell** (chosen, question 6).

### Decision

- **The rule.** Ivo's plane is the 2D world. The tower turns by φ about its axis: φ = u while Ivo rides, 0 off the stair on the floor, `head_u` on the gallery. What Ivo stands on or walks past off the stair (floor slab, gallery, alcove ledge, side walls, door) is static `.room` art in his plane. The view draws the stair and everything behind his plane (far wall, slits, posts, the floor's top, bell, beams), turned by -φ. Ivo stays at the stair's front on the axis, so nothing the view draws is in front of him on screen: the `ForegroundPass` cover, `DepthLook` and `frame_bias()` go.
- **Geometry** (`HelixStairShape`; bell tower values): `wall_radius` 144, `walk_radius` 96 (Ivo's plane), `inner_radius` 48, `pitch` 320, `turns` 3.5 (head rise 1120 px, 35 cells), `steps_per_turn` 32 (riser 10 px, tread 19 px at the walk radius), `eye_distance` 750, `speed_scale` 1. `tilt`, `far_scale`, `far_shade`, `near_art`, `far_art` go. `problems()`: inner < walk < wall < eye_distance, head rise a multiple of `RoomMap.CELL_PX`, `steps_per_turn` >= 8. `turns` need no longer be a multiple of 0.5.
- **Projection** (new pure `HelixProjection`). A point at tower angle θ, radius r, height y seen at φ: β = θ - φ, x3 = hand·r·sin β, z = r·cos β, k = (D - walk)/(D - z); screen = (axis.x + x3·k, eye + (y - eye)·k), eye = the camera's screen-centre y. k = 1 in Ivo's plane, so it maps 1:1 for every eye and φ. Front of the wall ×1.08, axis ×0.87, back ×0.73. The wall's silhouette half-width R(D - walk)/sqrt(D² - R²) is 128 px (127.95): the shell's inner faces stand there.
- **Path** (`HelixMath`). Feet = (0, -pitch·u/TAU) from the axis base. ω = run_speed·speed_scale/walk_radius, so the front tread passes under Ivo at his run speed and his feet do not skate: 2.0 rad/s, 102 px/s up, 11.0 s foot to head at 192 px/s. Step i spans u in [iΔ, (i+1)Δ) with its tread top at (i + 0.5)·riser, so the feet are within 5 px (riser/2) of the tread under them.
- **Faces** (new pure `HelixFaces`). For (shape, look, φ, eye), polygons back to front: wall blocks where cos β < R/D (the inner surface facing the eye), the floor's top, then steps (tread, riser, soffit, inner and outer stringer pieces), slits, posts and beams sorted by centroid depth, back faces culled. No step exists outside [0, head_u].
- **View** (new `HelixView`, built by `HelixStair`). A SubViewport the size of the shell's interior in art px (128 x 768 for the bell tower), transparent, `canvas_item_default_texture_filter` nearest (`gotchas/subviewport-does-not-inherit-default-texture-filter`), `UPDATE_ONCE` after each redraw. A Node2D in it draws `HelixFaces` with `draw_colored_polygon` and 1 px `draw_polyline`. A Sprite2D at scale 2 on the interior's top-left (a cell corner, so on the 2x grid) at z -15: behind the static `.room` art (0), in front of back walls (-20) and the backdrop (-30). It redraws when φ or the eye changed. It is root-canvas world art, so the greyhush greys it. It has no clock: φ and the eye come from Ivo and the camera, never from time, so it turns in the grey as the camera moves in the grey. Nothing joins `ForegroundPass`. The bell is the only sprite: it hangs on the axis, so it looks the same at every φ. It is drawn at its axis-depth size and only translated.
- **Input** (`HelixSteer.direction(axis, hand)`, static). Up or the hand side climbs; Down or the other side descends; |y| >= 0.5 wins a diagonal. No latch: the run's screen direction never changes at the front. Facing = hand × direction, constant through a climb.
- **Ends.** Foot: the axis on the floor at φ 0. Head: the axis on the gallery at φ = head_u. Boarding at the foot takes Up or the hand side, so walking from the door into the foot boards. Boarding at the head takes Down or the other side. At the head the hand side walks onto the gallery, fresh or held (hold right from the door to the gallery); Up holds. At the foot the other side walks onto the floor. `_outward_held` goes; `_held_at_leave` and the regrab delay stay. `clear_rider()` sets φ to head_u when released at the head, else 0 (debug teleports).
- **Collision.** The rider writes velocity = (axis.x - x, feet.y - y) / delta: a vertical sweep up the axis column. The gallery is one-way `-` planks across the shell; Ivo rises through it at the axis, and with no drop-through the well has no open edge. `HelixStair.check`: foot and head on cell tops; the capsule along the column meets no solid cell (one-ways pass: upward by the sweep, downward by the rider's teleport through a plank it rests on, `bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn`); 48 px of gallery on the hand side of the head; the shell's inner faces at the silhouette ±2 px on every row from floor to gallery.
- **Camera.** `Player.frame_bias()` and `GameCamera._frame_bias()` are removed: the feet now rise linearly. `air_axis()` and `look_axis()` stay 0 while riding.
- **Reach audit.** The STAIR role as built; `reach_ends` returns the floor cell on the other side of the foot and the gallery cell on the hand side of the head.
- **Data.** New `HelixLook` Resource (`resources/world/helix/`), read only by the view: colour ramps sampled from the board (wall stone 3 tones + mortar; timber 2 + line; tread 2 + nosing line; riser 2; soffit 2; stringer 3; slit glass 2 + frame; floor planks; beams), wall course height 24 px and block widths 40-64 px (hash-varied tone, a highlight line on top and left, a shadow line on bottom and right), slits as (angle, height) at 16 x 56 px, posts as angles (the board has two), the bell sprite and its anchor. `.room` params: `shape`, `look`, `hand`.
- **The bell tower `.room`** (20 x 48). Void cols 0-4 and 15-19 and rows 46-47; stone cols 5 and 14 (inner faces x 192 and 448); interior cols 6-13; roof row 0; floor row 45. The door at col 6, row 44 by the left wall. `@` at col 10, row 44 (axis x 320, base y 1440). The gallery is row 10, cols 6-13 (top y 320 = 1440 - 1120). The alcove ledge is row 4 at the right wall, 6 rows up (double jump, design 04 §3.1). The view draws the bell and beams in rows 1-3. Backdrop `interior_stone` (every room has one; the view covers it).

### What survives

- **Kept:** `MotionState.STAIR`, its refusals and buffer drops; `_try_board`; `HelixRiderComponent` (board, release, update, `end_pressed_into`, regrab, held-at-leave, held still while hit); `HelixEnd`; `HelixStair` as the place, with its ends and `reach_ends`, and `check` rewritten; `HelixMath.head_u` and `point_3d`; `feet` with x 0; `angular_speed` redefined; `HelixStairShape` with new fields; `HelixSteer` as one static function; the camera's zero air and look axes; the resolver's run and idle rows; `room_files_test.test_every_helix_stair_rides_clear`; the STAIR reach role and its tests.
- **Removed:** the Near, Far and Cover layers and the `CanvasPass.join_layer` call; `HelixMath.depth`, `facing`, `covers`, `nearness`, `frame_bias`, `screen_dx`, `into` and `half_turn_rise`; `HelixSteer`'s latch; `DepthLook`, its node in `ivo.tscn`, `Player._show_depth` and its test (`bugs/a-death-on-a-far-helix-run-keeps-ivo-darkened` becomes moot); `tools/art/bake_helix_stair.gd`, the half-turn images and their contracts; the slit props and `bell_tower_shaft.tres`.

### Art contract

`tools/art/prompts/helix_look_bell_tower.md` replaces `helix_stair_wood_near`, `helix_stair_wood_far`, `bell_tower_shaft` and `bell_tower_window_slit`. It is a palette and dimension contract: hex values sampled from the approved board (scratchpad `img_helix_board/raw.png`, "Approve (Recommended)", user, 2026-10-11; commit it as `tools/art/sources/bell_tower_board_codex.png`, the path `systems/helix-stair` names). No image is generated for the stair or the wall. The only image is `bell_tower_bell`, cut from the board by `cut_board_prop.py` at its axis-depth size (×0.87). The lighthouse is a second `HelixLook` in stone and iron. Before tuning, the user approves a still at φ 0, a quarter turn and the head, as for every style board.

### Tests

- `helix_projection_test`: Ivo's plane maps 1:1 for any eye and φ; the silhouette formula matches a brute-force maximum over the circle; below the eye the front of a ring projects lower than its back, above the eye higher; as φ grows, near points move one way on screen and far points the other; screw invariance: the stair's faces at (u + Δ, eye + riser) are those at (u, eye) moved up by one riser.
- `helix_faces_test`: back to front by depth; back faces culled; no step outside [0, head_u]; the tread under the feet within riser/2; no face nearer than Ivo's plane overlaps his capsule's screen rect at any u (sampled every 1/64 turn).
- `helix_math_test`: feet x 0, rise linear in u, the front tread's screen speed equals run_speed·speed_scale.
- `helix_steer_test`: Up and the hand side climb, Down and the other side descend, vertical wins at 0.5, mirrored for hand -1.
- `helix_rider_component_test`: boarding at the foot by Up and by walking in; a held hand-side press walks off the head onto the gallery; Up holds at the head; walking off the foot; velocity is vertical after boarding; `clear_rider()` leaves φ at 0 or head_u.
- `helix_stair_shape_test`: the new `problems()`.
- `helix_stair_test` (`check`): column clear, one-ways pass, gallery length, silhouette faces.
- `helix_view_test`: nearest filter; sprite at scale 2 on even game px; one redraw per change of φ or eye, none otherwise.
- `room_reach_test` passes on the rebuilt tower; the tower's contents stay in `tools/smoke/scenes.txt`; playtest timeline `bell_tower_helix_climb.json`: hold right from the door to the gallery, then left back down, with stills at u 0, a quarter turn, mid and head.

### Consequences

- One projection places all stair art; nothing else draws the stair.
- The stair, wall, slits and posts are flat-shaded geometry within the board's palette. If the still is not approved, the fallback is precomputed step-phase frames for the stair alone (screw symmetry), with the dressing kept as geometry.
- The eye is the camera's centre, read in `_process`. A camera moved by an idle tween is read a frame late (`gotchas/a-tween-runs-after-every-process-so-a-process-mirror-is-a-frame-late`): only off-plane parallax lags, never Ivo's plane.
- The door, floor, gallery and side walls do not turn: they are the cut, in Ivo's plane.
- A helix room holds no enemies or hazards: a knockback beside the foot would push Ivo into the stair's footprint.
- No user-facing text.

### Questions for the user

6. The top landing becomes a plank floor across the tower that Ivo climbs up through at the centre; the board shows a small landing at the right wall. (Recommended: it closes the well, so Ivo can never fall through the turning stair.)

### Answers (2026-10-11)

6. The top landing: "Floor across (Recommended)" (user, 2026-10-11): a full-width plank gallery at the head that Ivo rises through at the centre.

### Built (2026-10-11)

As decided, with these details: the view covers the shell from the room's top edge to the base (128 x 720 art px, the floor's static slab below it); faces are built only for the camera's window; a polygon that does not triangulate is skipped; the bell is cut at x0.235 board px per art px (46 x 54 px). `HelixStair` keeps the first version's `board_reach` (6 px) and `held` hold. `DepthLook`, the cover, the latch, the baker and the half-turn images are gone. After the user's "ivo while running doesn't touch the ground" (2026-10-11): the feet stand on the tread under the axis and climb each riser at once (`HelixMath.stand`), and `frame_bias()` returns so the camera follows the steady rise; the outer stringer cut by Ivo's plane is drawn as a solid band under the tread sections; the view draws the gallery's edge under its plank tiles.

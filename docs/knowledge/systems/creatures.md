---
id: systems/creatures
type: system
title: Corrupted creatures (CORE-13): a species is a scene plus EnemyStats; one generic move clock; every combat area script-owned; a fraying edge that is also the death and the waking
status: active
tags: [core-13, enemies, creatures, ai, enemy-move, enemy-stats, corruption-edge, shader, legend]
related: [architecture/corrupted-creatures, systems/guardians, systems/animation, systems/greyhush, systems/life-benches-death, systems/rooms, systems/air, bugs/the-brute-swings-away-from-a-target-already-in-reach, bugs/the-brute-walks-under-ivo-when-he-jumps-from-where-it-parks, bugs/one-swing-hits-the-brute-twice-when-its-shove-carries-it-out-and-back]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/enemies/enemy.gd
  - scenes/characters/enemies/enemy_ai.gd
  - scenes/characters/enemies/ai/walker_ai.gd
  - scenes/characters/enemies/ai/flyer_ai.gd
  - scenes/characters/enemies/ai/ceiling_ai.gd
  - scenes/characters/enemies/ai/thread_ai.gd
  - scenes/characters/enemies/ai/swoop_path.gd
  - scenes/characters/enemies/hit_guard.gd
  - scenes/characters/enemies/move_clock.gd
  - scenes/characters/enemies/enemy_reach.gd
  - scenes/characters/enemies/side_tracker.gd
  - scenes/characters/components/flight_component.gd
  - scenes/characters/components/corruption/corruption_edge.gd
  - scenes/characters/components/corruption/corruption_math.gd
  - scenes/characters/components/corruption/corruption_edge.gdshaderinc
  - scenes/characters/components/corruption/corruption_edge.gdshader
  - scenes/world/memory/unshielded_mark.gdshaderinc
  - scenes/world/memory/greyhush_creatures.gdshader
  - scenes/combat/hitbox/hitbox.gd
  - scenes/characters/creatures/boar/boar.tscn
  - scenes/characters/creatures/scorpion/scorpion.tscn
  - scenes/characters/creatures/crab/crab.tscn
  - scenes/characters/creatures/hornet/hornet.tscn
  - scenes/characters/creatures/bat/bat.tscn
  - scenes/characters/creatures/spider/spider.tscn
  - scenes/characters/creatures/spider/silk_thread.gd
  - scenes/characters/creatures/spider/silk_thread.gdshader
  - resources/characters/enemies/enemy_stats.gd
  - resources/characters/enemies/enemy_move.gd
  - resources/characters/creatures/
  - resources/world/maps/room_legend.tres
  - tests/scenes/combat/combat_reach_test.gd
  - tests/scenes/characters/creatures/creature_sheet_test.gd
  - tests/scenes/world/rooms/maps/room_files_test.gd
---

# Corrupted creatures

**Never break:** a species is a scene plus an `EnemyStats`, never a subclass of `Enemy`; its only code is its animation resolver. Every `Area2D` property on a creature is written by `Enemy._sync_areas` each physics frame, never keyed in a clip and never written from a physics-flush signal; clips key only `Sprite2D` texture, hframes and frame (`creature_sheet_test`). `CorruptionEdge` is the only writer of the corruption-edge uniforms, and the shader animates only from `greyhush_time`, in the sprite's own art-pixel grid.

The plan, its options and the build order: [`architecture/corrupted-creatures`](../architecture/corrupted-creatures.md). Round 1 (2026-10-29) built the boar and the scorpion; round 2 (same day) the crab, hornet, icicle bat and spider. All six are built and placed.

## Pieces

- **Data.** `EnemyMove` (one attack: `telegraph`, `active`, `recovery`, `cooldown` in s; `reach: Rect2` px from the feet, authored facing east; `lunge_speed`; `ends_on_wall`; `armoured`; `hitbox`, the child `Hitbox` it arms; `damage`, `knockback_strength`, `knockback_lift`, the `GuardianAttack` names). `EnemyStats` (health, contact damage and knockback, `sight_radius`, `wake_radius`, `hidden_until_woken`, `leash`, `wanders`, `stop_distance`, `locomotion`, `moves` in priority order, wander durations; `validate()`). `Enemy._ready` pushes it into `Health`, `ContactHitbox`, the `EnemySight` and `WakeTrigger` circles (duplicated, so the scorpion and its bait never share one), `Locomotion` or `Flight`, and the AI.
- **`MoveClock`** (pure): READY, TELEGRAPH, ACTIVE, RECOVER, COOLDOWN; leftover time carries into the next phase; `end_active()` (a wall or a ledge) goes to RECOVER; `cancel()` keeps the cooldown; `phase_entered` drives `EnemyAI`'s `move_telegraphed`, `move_started`, `move_finished`.
- **`EnemyReach`** (pure): a target is inside a move's box mirrored to the facing, edges included. **`SideTracker`** (pure): the target's side is committed only outside `TURN_BAND` (10 px).
- **`EnemyAI`** (the generic machine): DORMANT until `wake()` (home is where it stood), then IDLE, APPROACH, HOME, TELEGRAPH, ACTIVE, RECOVER. The target is `EnemySight.visible_presence()` taken once per tick (a Sombra shadow counts). The clock ticks before the state is chosen. When READY, the first move whose reach holds the target starts, aimed at the committed side, and keeps that side until it ends. Standing with a target it faces the target; otherwise it faces where it steers. A hit cancels a telegraph and an unarmoured hit window; a recovery is never cancelled (the punish window). Output: `steer: Vector2` (px/s); `direction` is `signf(steer.x)`.
- **`WalkerAI`**: wanders (if `wanders`) or holds home; closes in on x only to `stop_distance`, never past `leash` from home; a lunge runs along the facing at `lunge_speed`; a ledge on the facing side (`ledge_ahead`, written by the body from `LedgeProbe`) stops any step that way and ends a lunge that `ends_on_wall`, as a new wall contact does; with no target, a creature that does not wander walks home.
- **`Enemy`** (the body): areas are on only while `is_present()` (not dead, and woken and gathered if `hidden_until_woken`): `Hurtbox.monitorable`, `ContactHitbox.monitoring`; the current move's hitbox only during ACTIVE (its damage pushed at `move_started`); `Guard` while not recovering. Once the current move has landed a hit (`Hitbox.hit_landed`: a hit on a hurtbox that was not invulnerable, from the move's hitbox, or from the contact during ACTIVE or RECOVER), `ContactHitbox` and `Guard` stay off until the move ends, recovery included: one move costs one life (`bugs/a-boar-charge-that-hits-ivo-by-a-ledge-dazes-inside-him-and-contact-takes-a-second-life`). The AI ticks only while present (knockback included, so a daze runs out under a combo); steer is applied only out of knockback. A lunge passes an axis above 1 to `LocomotionComponent.ground_update`. An armoured hit window takes damage without knockback. A hazard kills. `died` marks `save_id` defeated and starts the vanish; the body frees once `CorruptionEdge.is_gone()`.
- **`FlightComponent`**: velocity toward `steer + wind * air_wind`, no gravity: the hornet, the bat and the spider. Their bodies use `motion_mode` FLOATING, so any surface is a wall (`handle_wall_contact`); they skip gravity and have no ledge probe.
- **Facing** (`EnemyAI._get_facing_direction`): a move keeps its side; under `FACE_DEADBAND` (12 px/s of `steer.x`) it faces its target, or keeps its facing without one; above it, it faces where it steers. `FlyerAI` always faces its target; `WalkerAI.always_face_target` (the crab) does too outside a move.
- **`EnemyAI._enter_phase(phase)`**: a style's hook when a move phase begins, before its first tick: the hornet locks its hold point at TELEGRAPH and its aim at ACTIVE; the bat builds its `SwoopPath` at ACTIVE. `is_home()` (asleep counts) is what the bat's and the spider's resolvers read to hang or rest. `CHEST` (y -28, the centre of Ivo's hurtbox) is where a flyer aims on its target.
- **`FlyerAI`** (hornet): hovers at home on a bob (`bob_height`, `bob_period`); with a target, holds a point `hover_distance` beside it at its chest, inside `leash` of home; at the end of the telegraph it locks `aim_at(position, target feet)` and dashes at `aim * lunge_speed`. `FlightComponent` adds the wind, so a current bends the dash. A wall ends the dash (`ends_on_wall`); it drifts through the recovery.
- **`CeilingAI`** (bat): waits at its anchor (home, where it was placed) and never chases; when the target is inside the swoop's reach (below it) it drops (the telegraph), then at ACTIVE builds a `SwoopPath` from where it is through the target's chest and follows it with `swoop_steer` (the path's velocity plus `CATCH_UP` times the error); the path's end or a wall ends ACTIVE; it flies back and hangs. `SwoopPath` (pure): x at a constant rate, y on a parabola through the target at the midpoint, ending at the start's mirror at the start's height; `duration = 2 |target - start| / speed`.
- **`ThreadAI`** (spider): rests at home; with a target within `column_half_width` of its column it lets itself down to the target's chest (`chest_height` over its own origin), no farther than `max_drop`, at `descend_speed`, and climbs at `climb_speed`; after `linger` s without a target in its column it climbs back. It moves sideways only to swing back under its anchor after a knock. `anchor()` is home minus `anchor_height` (16, the placed cell's top). `SilkThread` (top level, so its grid is tied to the ceiling) draws a 2 px line from the anchor to the spider each frame; its shader opens gaps along it in art pixels on `greyhush_time` and writes the unshielded alpha. It joins the creature pass with its body (`CanvasPass.join_layer` walks the children) and hides at death.
- **The front guard** (crab): with `EnemyStats.front_guard`, `Enemy._on_hit_received` asks `HitGuard.blocks(facing, body_rect(), source.global_position)`: a hit from ahead whose source is below the body's top is blocked: no damage, no knockback, no cancel, a white flash (`BLOCK_FLASH`, an over-bright modulate the shader multiplies in), and `blocked` is emitted. Ivo's hitbox origin is his feet, so a pogo (feet over the shell) and a hit from behind land. Ivo gets no recoil (`Player` bounces only on a pogo). User, 2026-10-29: "1 damage; shell blocks (Recommended)".
- **A hit wakes** a creature drawn asleep (the bat, the spider) before its knockback, so home is where it was struck. **Wind carries only an awake creature**: a hanging bat or a creature not yet gathered stays where it was placed.

**Teachers are not creatures of this system** (CORE-04, `systems/teaching-creatures`): a `TeachingCreature` is a `Node2D` with no body, health, hurtbox or `CorruptionEdge`, so it carries no unshielded mark and its own SILHOUETTE `GreyhushShield` colours it. Their rooms hold no corrupted creature (`room_files_test.NO_CREATURE_ROOMS`).

## The corruption edge

`corruption_edge.gdshaderinc` (canvas_item) holds the uniforms and the pure helpers; `corruption_edge.gdshader` is the fragment every species uses.

- **Grid:** art pixels of the current frame: `floor(UV / TEXTURE_PIXEL_SIZE)` made frame-local with `frame_size`, then `/ art_scale` (2 texels per art pixel). It travels with the body and does not re-roll on a frame change.
- **Edge:** 1 with a transparent 4-neighbour 1 art px away, 0.5 at 2; outside the frame reads transparent.
- **Fray:** an opaque pixel deserts when `edge * (fray + agitation)` exceeds its Bayer threshold, the matrix shifted each epoch (`floor(greyhush_time / reroll_period + seed)`, 0.25 s).
- **Dissolve:** 0..1 eats from the edge inward (`dissolve > 0.5 (1 - edge) + 0.5 threshold`); 1 draws nothing.
- **Strays:** a transparent pixel may draw the edge pixel 1..3 art px behind it along `drift`, chosen by a hash of the source and the epoch.
- **Colour:** the texel times the vertex colour (a varying from `vertex()`), so `Character.flash` shows.
- **Custom shader functions cannot read `TEXTURE`** (and passing `TEXTURE` as a `sampler2D` argument fails to compile), so the samplers are macros (`CE_ALPHA`, `CE_COLOUR`, `CE_EDGE`) expanded in `fragment()`. Godot's preprocessor substitutes a macro parameter inside a member access (`a` in `.a`), so their parameters are `CE_O` and `CE_P`.

`CorruptionEdge` (pausable) writes `fray` (`CorruptionMath.fray(rest_fray, hurt_fray, hp, max_hp)` plus a hit spike fading over 0.3 s), `agitation` (on from `move_telegraphed` to `move_started` or `move_finished`: the tell lives in the fraying), `dissolve`, `seed`, `frame_size` and `drift`. `appear()` and `vanish()` tween the dissolve on a node-bound tween (pausable, scaled). It puts the body on `CanvasPass.CREATURES`; creatures carry no `GreyhushShield`, so the creature composite greys them by the memory field. The shader writes alpha `GH_UNSHIELDED_ALPHA` (253/255) on every pixel it draws, and the composite lights those pixels by the field only, so no one else's shield (Ivo's SILHOUETTE shield in melee, a teacher's later) colours a creature (`systems/greyhush`, "Unshielded pixels"). There is no GDScript twin: gameplay never reads the fray.

## Species

Frame sizes and clips are in `tools/art/prompts/creature_<species>_<clip>.md`; strips face west (`Sprite2D.scale.x = -1`) and stand on the frame's bottom row (`Sprite2D.position.y = -32`).

| Species | hp | Move: telegraph / active / recovery / cooldown (s) | Reach (px, facing east) | Other |
|---|---|---|---|---|
| boar | 4 | charge: 0.6 / 1.2 max / 1.0 daze / 0.8; lunge 300 px/s, `ends_on_wall`, `armoured` | x 0..192, y -64..16 | walk 60; wanders; stop 56; sight 320, wake 200 |
| scorpion | 5 | strike: 0.7 / 0.2 / 0.8 stuck / 0.8 | x 0..46, y -56..8 | walk 50; holds home; leash 192; stop 36; sight 280, wake 200; `Guard` over the raised tail (y -60..-28) |
| scorpion bait | 8 | strike_bait: 0.55 / 0.2 / 0.6 / 0.5 | same | leash 320; sight 366, wake 200 (the lure tests) |
| crab | 3 | snap: 0.4 / 0.2 / 0.4 / 1.0 | x 0..32, y -16..8 | walker, sidestep 70; holds home; leash 192; stop 28; `front_guard`; `always_face_target`; sight 256, wake 200 |
| hornet | 2 | dash: 0.5 / 0.5 max / 0.6 / 1.2; lunge 380 px/s, `ends_on_wall` | x 0..160, y -8..48 (from its centre) | flyer, hover 90, acceleration 2400; `hover_distance` 128; leash 384; `air_wind` 0.6; sight 320, wake 200 |
| icicle bat | 2 | swoop: 0.3 drop / path (2.5 max) / 0.6 / 1.5; path speed 240 px/s, `ends_on_wall` | x -24..128, y 48..224 (below its anchor) | ceiling, fly 120, acceleration 2400; drawn asleep; sight 280, wake 224 |
| spider | 2 | bite: 0.35 / 0.2 / 0.5 / 0.9 | x 0..30, y 5..37 (from its centre) | thread, descend 140, climb 80, `max_drop` 256, column 64, `linger` 1.5; drawn asleep; no `AirflowBody`; sight 256, wake 192 |

The weak clips (boar tell, charge, daze; scorpion strike, stuck; spider climb; hornet dash) are carried by the timing data and the agitation spike. The scorpion's strike, the crab's snap and the spider's bite are 4 frames at 20 fps, equal to `active` (`creature_sheet_test`). Walkers stand on the frame's bottom row (`Sprite2D.position.y` -32, the crab's -24); the hornet and the bat are centred on their origin; the bat's `hang` clip keys `Sprite2D.offset` (0, 16), so it hangs from its cell's top (the other clips get (0, 0) from `RESET`); the spider's origin is its body's centre (`position.y` -11), so it rests under the cell above instead of in it. Clip rates: idle 6 fps, walk and sidestep 10, hover and fly 12, tells 8 (the crab's 2-frame tell 5), dash 12, recover 6, drop and swoop 10, climb 10, bob 8, hang 3, hurt 10. Every hitbox is a static shape; for walkers `combat_reach_test` holds that a standing move's hitbox touches a grounded Ivo from its contact reach out to `reach.end.x`, that a lunge touches him somewhere, that Ivo's slash and chop land on a walker parked at `stop_distance` (swing 1's shove included), and that `stop_distance` is outside its contact reach. For flyers it holds that the bite touches an Ivo at the reach's top and bottom from where its contact hurts out to `reach.end.x`, and that the dash and the swoop, flown frame by frame through `FlightComponent.steered` from the AI's own steer (`FlyerAI.aim_at`, `CeilingAI.swoop_steer`), touch an Ivo standing at each corner of the reach.

## Placements

16 in the world plus the trial lure; `save_id` is `<room>_<species>[_<n>]`. Cells are the room's (the feet cell for `B J C`, the hanging or floating cell for `N A Z`); world positions are the feet for walkers and the origin for the others.

| Room | Symbol, cell | save_id | World (px) |
|---|---|---|---|
| `threshold_bridge` | `B` 31,4 | `threshold_bridge_boar` | round 1 |
| `frost_shore` | `C` 10,8 and 26,8 | `frost_shore_crab_1`, `_2` | (8656, 288), (9168, 288) |
| `frost_wreck_hold` | `C` 15,6 | `frost_wreck_hold_crab` | (26096, 12224) |
| `lake_ice_caves` | `A` 6,2 and 34,3 | `lake_ice_caves_bat_1`, `_2` | (3408, -1840), (4304, -1808) |
| `woods_deep` | `Z` 46,12 and 52,16 (under the row-11 and row-15 branches) | `woods_deep_spider_1`, `_2` | (-2992, -368), (-2800, -240) |
| `woods_canopy` | `Z` 12,5 (under the launch branch) | `woods_canopy_spider` | (-4080, -976) |
| `orchard_chasm_bridge` | `N` 16,5 and 30,4 | `orchard_chasm_bridge_hornet_1`, `_2` | (-3952, -2128), (-3504, -2160) |
| `orchard_summit` | `N` 31,12 | `orchard_summit_hornet` | (-4752, -2288) |
| `caldera_cistern_bottom` | `J` 34,20 | `caldera_cistern_bottom_scorpion` | (464, 1824) |
| `caldera_sun_stair` | `J` 5,20 and 13,26 (an L and an R shelf) | `caldera_sun_stair_scorpion_1`, `_2` | (4016, 1056), (4272, 1248) |
| `caldera_bait` | `J` 19,8, bait stats | `caldera_bait_scorpion` (`id` `bait_scorpion`) | round 1 |
| `summer_trial` | `J` 53,15, bait stats | `summer_trial_scorpion` (`id` `lure_scorpion`) | round 1, a trial |

`room_files_test` holds the rules: a bat under a solid cell with 5 open cells below, a spider under ground or a one-way with 3 (it rests under a branch and only has to let itself down over Ivo); no creature in the village, an arena, the lighthouse, a teacher's room or `threshold_fields`; the world count per species.

## User decisions (2026-10-29), verbatim

1. Waking: "Gather out of the grey (Recommended)": boar, crab, scorpion and hornet form out of the grey (the dissolve reversed) when Ivo comes near; the bat and spider are drawn asleep.
2. Contact and shell: "1 damage; shell blocks (Recommended)": touching any creature costs 1; a hit on the crab's shell does no damage, flashes it white, no recoil on Ivo.
3. Bait scorpion: "Faster and sturdier (Recommended)": 8 hp, telegraph 0.55 s, stuck 0.6 s, cooldown 0.5 s, same damage.
4. The rest: "Accept (Recommended)": the 16 placements plus the trial lure; the fray keeps flickering on `greyhush_time` during a song's freeze; `room_legend.tres` may be committed on top of its uncommitted changes (Godot editor re-save of defaults only).

## Gotchas

- A `Node`-typed export in a hand-written `.tscn` needs `node_paths=PackedStringArray(...)` on the node line, or it loads as null (`CorruptionEdge.sprite`, `health`).
- Pause mode: everything on a creature is pausable; nothing joins the ALWAYS list (`systems/songs-and-the-memorina`). Under a song's freeze the body stands still and the edge keeps re-rolling, because `greyhush_time` runs.

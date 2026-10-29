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
  - resources/characters/enemies/enemy_stats.gd
  - resources/characters/enemies/enemy_move.gd
  - resources/characters/creatures/
  - resources/world/maps/room_legend.tres
  - tests/scenes/combat/combat_reach_test.gd
  - tests/scenes/characters/creatures/creature_sheet_test.gd
---

# Corrupted creatures

**Never break:** a species is a scene plus an `EnemyStats`, never a subclass of `Enemy`; its only code is its animation resolver. Every `Area2D` property on a creature is written by `Enemy._sync_areas` each physics frame, never keyed in a clip and never written from a physics-flush signal; clips key only `Sprite2D` texture, hframes and frame (`creature_sheet_test`). `CorruptionEdge` is the only writer of the corruption-edge uniforms, and the shader animates only from `greyhush_time`, in the sprite's own art-pixel grid.

The plan, its options and the build order: [`architecture/corrupted-creatures`](../architecture/corrupted-creatures.md). Round 1 (2026-10-29) built the boar and the scorpion; the crab, bat, spider and hornet are round 2.

## Pieces

- **Data.** `EnemyMove` (one attack: `telegraph`, `active`, `recovery`, `cooldown` in s; `reach: Rect2` px from the feet, authored facing east; `lunge_speed`; `ends_on_wall`; `armoured`; `hitbox`, the child `Hitbox` it arms; `damage`, `knockback_strength`, `knockback_lift`, the `GuardianAttack` names). `EnemyStats` (health, contact damage and knockback, `sight_radius`, `wake_radius`, `hidden_until_woken`, `leash`, `wanders`, `stop_distance`, `locomotion`, `moves` in priority order, wander durations; `validate()`). `Enemy._ready` pushes it into `Health`, `ContactHitbox`, the `EnemySight` and `WakeTrigger` circles (duplicated, so the scorpion and its bait never share one), `Locomotion` or `Flight`, and the AI.
- **`MoveClock`** (pure): READY, TELEGRAPH, ACTIVE, RECOVER, COOLDOWN; leftover time carries into the next phase; `end_active()` (a wall or a ledge) goes to RECOVER; `cancel()` keeps the cooldown; `phase_entered` drives `EnemyAI`'s `move_telegraphed`, `move_started`, `move_finished`.
- **`EnemyReach`** (pure): a target is inside a move's box mirrored to the facing, edges included. **`SideTracker`** (pure): the target's side is committed only outside `TURN_BAND` (10 px).
- **`EnemyAI`** (the generic machine): DORMANT until `wake()` (home is where it stood), then IDLE, APPROACH, HOME, TELEGRAPH, ACTIVE, RECOVER. The target is `EnemySight.visible_presence()` taken once per tick (a Sombra shadow counts). The clock ticks before the state is chosen. When READY, the first move whose reach holds the target starts, aimed at the committed side, and keeps that side until it ends. Standing with a target it faces the target; otherwise it faces where it steers. A hit cancels a telegraph and an unarmoured hit window; a recovery is never cancelled (the punish window). Output: `steer: Vector2` (px/s); `direction` is `signf(steer.x)`.
- **`WalkerAI`**: wanders (if `wanders`) or holds home; closes in on x only to `stop_distance`, never past `leash` from home; a lunge runs along the facing at `lunge_speed`; a ledge on the facing side (`ledge_ahead`, written by the body from `LedgeProbe`) stops any step that way and ends a lunge that `ends_on_wall`, as a new wall contact does; with no target, a creature that does not wander walks home.
- **`Enemy`** (the body): areas are on only while `is_present()` (not dead, and woken and gathered if `hidden_until_woken`): `Hurtbox.monitorable`, `ContactHitbox.monitoring`; the current move's hitbox only during ACTIVE (its damage pushed at `move_started`); `Guard` while not recovering. Once the current move has landed a hit (`Hitbox.hit_landed`: a hit on a hurtbox that was not invulnerable, from the move's hitbox, or from the contact during ACTIVE or RECOVER), `ContactHitbox` and `Guard` stay off until the move ends, recovery included: one move costs one life (`bugs/a-boar-charge-that-hits-ivo-by-a-ledge-dazes-inside-him-and-contact-takes-a-second-life`). The AI ticks only while present (knockback included, so a daze runs out under a combo); steer is applied only out of knockback. A lunge passes an axis above 1 to `LocomotionComponent.ground_update`. An armoured hit window takes damage without knockback. A hazard kills. `died` marks `save_id` defeated and starts the vanish; the body frees once `CorruptionEdge.is_gone()`.
- **`FlightComponent`**: velocity toward `steer + wind * air_wind`, no gravity; built and tested in round 1, first used by the round-2 flyers.

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

## Species (round 1)

Frame sizes and clips are in `tools/art/prompts/creature_<species>_<clip>.md`; strips face west (`Sprite2D.scale.x = -1`) and stand on the frame's bottom row (`Sprite2D.position.y = -32`).

| Species | hp | Move: telegraph / active / recovery / cooldown (s) | Reach (px, facing east) | Other |
|---|---|---|---|---|
| boar | 4 | charge: 0.6 / 1.2 max / 1.0 daze / 0.8; lunge 300 px/s, `ends_on_wall`, `armoured` | x 0..192, y -64..16 | walk 60; wanders; stop 56; sight 320, wake 200 |
| scorpion | 5 | strike: 0.7 / 0.2 / 0.8 stuck / 0.8 | x 0..46, y -56..8 | walk 50; holds home; leash 192; stop 36; sight 280, wake 200; `Guard` over the raised tail (y -60..-28) |
| scorpion bait | 8 | strike_bait: 0.55 / 0.2 / 0.6 / 0.5 | same | leash 320; sight 366, wake 200 (the lure tests) |

The weak clips (boar tell, charge, daze; scorpion strike, stuck) are carried by the timing data and the agitation spike. The scorpion's strike clip is 4 frames at 20 fps, equal to `active` (`creature_sheet_test`). Every hitbox is a static shape; `combat_reach_test` holds that a standing move's hitbox touches a grounded Ivo from its contact reach out to `reach.end.x`, that a lunge touches him somewhere, that Ivo's slash and chop land on a walker parked at `stop_distance` (swing 1's shove included), and that `stop_distance` is outside its contact reach.

Placements: `B` boar at `threshold_bridge` 31,4 (`threshold_bridge_boar`); `J` scorpion with the bait stats at `caldera_bait` 19,8 (`bait_scorpion`, `caldera_bait_scorpion`) and the summer trial's lure 53,15 (`lure_scorpion`, `summer_trial_scorpion`). The remaining scorpion placements (`caldera_cistern_bottom`, `caldera_sun_stair`) are round 2 (plan step 3).

## User decisions (2026-10-29), verbatim

1. Waking: "Gather out of the grey (Recommended)": boar, crab, scorpion and hornet form out of the grey (the dissolve reversed) when Ivo comes near; the bat and spider are drawn asleep.
2. Contact and shell: "1 damage; shell blocks (Recommended)": touching any creature costs 1; a hit on the crab's shell does no damage, flashes it white, no recoil on Ivo.
3. Bait scorpion: "Faster and sturdier (Recommended)": 8 hp, telegraph 0.55 s, stuck 0.6 s, cooldown 0.5 s, same damage.
4. The rest: "Accept (Recommended)": the 16 placements plus the trial lure; the fray keeps flickering on `greyhush_time` during a song's freeze; `room_legend.tres` may be committed on top of its uncommitted changes (Godot editor re-save of defaults only).

## Gotchas

- A `Node`-typed export in a hand-written `.tscn` needs `node_paths=PackedStringArray(...)` on the node line, or it loads as null (`CorruptionEdge.sprite`, `health`).
- Pause mode: everything on a creature is pausable; nothing joins the ALWAYS list (`systems/songs-and-the-memorina`). Under a song's freeze the body stands still and the edge keeps re-rolling, because `greyhush_time` runs.

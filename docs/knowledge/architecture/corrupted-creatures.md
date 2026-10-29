---
id: architecture/corrupted-creatures
type: architecture
title: Corrupted creatures (CORE-13) - six species as scenes plus EnemyStats, one generic move clock, four movement styles, every combat area script-owned, a shared fraying-edge material that is also the death and spawn dissolve
status: built
tags: [core-13, enemies, creatures, ai, enemy-move, enemy-stats, corruption-edge, shader, greyhush, animation, legend, rooms, save, plan]
related: [architecture/guardian-fight-phase-machine, architecture/animation-driver-resolver-pattern, architecture/character-controller-input-split, architecture/one-air-channel, architecture/weight-and-presence, architecture/the-life-loop-rewinds-by-reloading, architecture/rooms-are-text, architecture/room-reachability-audit, architecture/memory-field-cpu-gpu-split, architecture/foreground-layer, systems/guardians, systems/animation, systems/greyhush, systems/foreground, systems/life-benches-death, systems/rooms, systems/songs-and-the-memorina, systems/air, systems/bell-jar, systems/water, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/sprite-frame-out-of-bounds-on-clip-switch, gotchas/subviewport-does-not-inherit-default-texture-filter, gotchas/monitorable-false-hides-an-area-from-every-monitor, gotchas/glsl-floor-division-modulo-can-return-the-divisor, gotchas/scene-resave-buries-real-edits-in-noise, bugs/the-brute-swings-away-from-a-target-already-in-reach, bugs/the-brute-walks-under-ivo-when-he-jumps-from-where-it-parks, bugs/one-swing-hits-the-brute-twice-when-its-shove-carries-it-out-and-back, bugs/creature-pass-frozen-transform-floats-bodies, bugs/creature-pass-bilinear-blur]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/enemies/enemy.gd
  - scenes/characters/enemies/enemy_ai.gd
  - scenes/characters/enemies/brute_shadow/brute_shadow.gd
  - scenes/characters/enemies/brute_shadow/brute_shadow_ai.gd
  - scenes/characters/components/ai_controller.gd
  - scenes/characters/components/enemy_sight.gd
  - scenes/characters/components/locomotion_component.gd
  - scenes/characters/components/airflow_body.gd
  - scenes/characters/components/player_proximity_trigger.gd
  - scenes/characters/character.gd
  - scenes/combat/hitbox/hitbox.gd
  - resources/characters/guardians/guardian_attack.gd
  - resources/characters/enemies/brute_shadow/brute_shadow_attack_stats.gd
  - resources/characters/enemy_ai_stats.gd
  - resources/world/maps/room_legend.tres
  - scenes/world/memory/greyhush_creatures.gdshader
  - scenes/world/memory/dither_common.gdshaderinc
  - tests/scenes/combat/combat_reach_test.gd
  - tests/scenes/world/rooms/trials/summer_trial_test.gd
---

# Corrupted creatures (CORE-13)

**Status: built** (2026-10-29, rounds 1 and 2; the entry is [`systems/creatures`](../systems/creatures.md)). Design: `docs/design/02_mecanicas.md` §1-§2 ("Criaturas escolhidas", user, 2026-10-29) and `docs/design/drafts/creatures_board.md` "Decided". The art is committed: one strip per clip in `assets/sprites/characters/creatures/<species>/<species>_<clip>.png`, contracts in `tools/art/prompts/creature_<species>_<clip>.md`. Teaching creatures (CORE-04) are out of scope; this plan only keeps their folder free.

## Context

- **What replaces what.** The six picks: Threshold boar (takes the brute's cell in `threshold_bridge`, 31,4), Frost Edge crab, Frozen Lake icicle bat, Spring Woods spider, Wind Orchards hornet, Summer Caldera scorpion plus a tougher bait variant guarding `caldera_bait` ("A isca"). No enemy in the village. The brute is placed three times, not once: `threshold_bridge` 31,4 (`threshold_bridge_brute`), `caldera_bait` 19,8 (`caldera_bait_brute`, `id` `bait_brute`) and the summer trial's lure 53,15 (`summer_trial_brute`, `id` `lure_brute`). The two lures need a territorial creature, so the brute can retire only when the scorpion exists.
- **The brute today.** `BruteShadow extends Enemy extends Character`; `BruteShadowAI extends EnemyAI extends AIController` (WANDER, CHASE, ATTACK); `BruteShadowAttackStats` (duration, range, stop distance, cooldown); a flat `AnimationTree` whose clips KEY `Hurtbox:monitorable`, `Hitbox:*` and `CollisionHitbox:monitoring` under a `RESET` track (so the tree stays inactive until spawn: `systems/animation`); hidden until a `PlayerProximityTrigger` (200 px) wakes it, after a drawn spawn clip; a drawn death clip; a `GreyhushShield` (amount 0.422) that put it on the creature pass. Its lessons are in three bug files (face a target in reach while standing, park on horizontal distance, keep the side inside `TURN_BAND`; `strikes_once`).
- **What the art gives.** No death or spawn clip ("a shader dissolves them"). Frame sizes per species (game px, 2x art): boar 96x64, crab 64x48, bat 64x64, spider 48x48, hornet 48x48, scorpion 80x64. Every strip faces **west** (the brute's `Sprite2D.scale.x = -1` convention). Walkers and the spider stand on the frame's bottom row; the hornet is centred; the bat's `hang` hangs from the top row. Clips:

  | Species | Clips (frames) |
  |---|---|
  | boar | idle 4, walk 6, tell 3, charge 4, daze 4, hurt 2 |
  | crab | idle 4, sidestep 6, tell 2, snap 4, hurt 2 |
  | bat | hang 2, drop 3, fly 6, swoop 3, hurt 2 |
  | spider | idle 4, climb 4, bob 4, bite 4, hurt 2 (thread drawn in code) |
  | hornet | hover 4, tell 3, dash 3, recover 3, hurt 2 |
  | scorpion | idle 4, walk 6, tell 3, strike 4, stuck 3, hurt 2 |

  Eight clips are weak and kept: "movement, timing and the glitch shader carry them" (user, 2026-10-29). So timing must be data, tunable without re-keying clips.
- **Rules that bind.** Animation: the resolver owns every clip name as a `const`, no transitions; a property with a `RESET` track is overwritten every frame. Greyhush: dither on a stable pixel grid, never `FRAGCOORD`; animate from `greyhush_time`, never `TIME`; characters never freeze by memory. Every species takes its target from `EnemySight.visible_presence()` (the Sombra shadow counts as Ivo, design 02 §7.1). Redoma's shell (layer 4) bars matter, not creatures (`systems/bell-jar`). Wind is a velocity the air carries (`systems/air`). Defeated enemies live in the save ledger only and return at a rest or a death (`systems/life-benches-death`). A placeable is a legend entry whose root exports are its params (`systems/rooms`).

## Options considered

**1. How a species differs from another.**
- One subclass per species (`Boar extends Enemy`, `BoarAI extends EnemyAI`), as the brute did. Rejected: six bodies and six AIs that are 90% the same telegraph-strike-recover loop; the brute's bugs would be fixed six times.
- One `Enemy` script with a `species` enum and a `match`. Rejected: Open/Closed, the branch the guardians entry forbids.
- **Chosen:** a species is a **scene plus an `EnemyStats`** (as "a concrete guardian is a scene plus `GuardianStats`"); the only per-species code is its animation resolver (clip vocabulary, a rule of `systems/animation`). Behaviour that differs by body plan is one of four **movement styles** (`WalkerAI`, `FlyerAI`, `CeilingAI`, `ThreadAI`), each a small `EnemyAI` subclass. The bait scorpion is the scorpion scene with another `EnemyStats`.

**2. The attack data.**
- Reuse `GuardianAttack`. Rejected: it carries guardian-only fields (`recall`, `clip_index` into the guardian resolver, `leap_impulse`, a single `duration` that must equal one clip), and creatures need an active window that ends early on a wall.
- A shared abstract base for `GuardianAttack` and `EnemyMove`. Rejected for now: inheritance on a non-engine base (CLAUDE.md), and it would touch the guardians for no gain to them.
- **Chosen:** a new `EnemyMove` Resource whose shared fields keep `GuardianAttack`'s names and units (`telegraph`, `cooldown`, `lunge_speed`, `damage`, `knockback_strength`, `knockback_lift`), with the guardian's single `duration` split into `active` + `recovery`, and its range-and-height box generalised to a facing-relative `reach: Rect2` (the scorpion reaches forward, the bat and spider below; "a move reaches inside a BOX", `systems/guardians`). `EnemyStats` replaces `BruteShadowAttackStats` and `EnemyAIStats`.

**3. Who owns the hitboxes.**
- Key them in the clips, as the brute and the guardians do. Rejected: a charge or a dash runs until a wall or a timer, not for a fixed clip length; every weak clip would need re-keying to retune; and a keyed area under `RESET` is the trap in `gotchas/animationtree-reset-track-overwrites-script-writes`, which is why the brute had to keep its tree off until spawn.
- **Chosen:** every `Area2D` property on a creature is **script-owned**, written each physics frame from the AI's phase (the guardians' `ContactHitbox` precedent). Clips key only `Sprite2D` `texture`, `hframes`, `frame` (hframes before frame: `gotchas/sprite-frame-out-of-bounds-on-clip-switch`) and, for the bat's `hang`, `offset`. Hitbox geometry is a static shape in the scene, one `Hitbox` node per move.

**4. Motion.**
- One AI output, `direction: float`, as today. Rejected: the hornet, the bat and the spider move in two dimensions or only vertically.
- A motor strategy class per style. Rejected: four motors for two real cases.
- **Chosen:** `EnemyAI.steer: Vector2` (desired velocity, px/s). Two motors: the existing `LocomotionComponent` with gravity for walkers, and a new generic `FlightComponent` (no gravity) for the bat, spider and hornet, chosen by which child the scene has. `direction` stays (CharacterController's contract) as `signf(steer.x)`.

**5. The corruption edge.**
- A fourth drawn clip per species for death and spawn. Rejected by the art decision.
- Read the edge from the memory field per pixel. Rejected: the fray is the creature's own state (hurt, telegraphing, dying), not the ground's, and the composite already greys it by the field.
- **Chosen:** one canvas-item shader include, `corruption_edge.gdshaderinc`, on each creature's `Sprite2D`, in the sprite's own art-pixel grid, re-rolled on `greyhush_time`; one `CorruptionEdge` node writes three uniforms (`fray`, `dissolve`, `agitation`). Death is a full dissolve, waking its reverse.

**6. Clock for the fray.**
- A per-creature uniform clock on the pausable tree, so the fray stops with the creature under a performance freeze. Rejected: a second clock that disagrees with the greyhush edge it is a part of.
- **Chosen:** `greyhush_time`. It stops under a menu hold, slows with a recall, and keeps re-rolling through a performance freeze, as the greyhush's own edge does; the body and its tweens stay pausable. (Question 5 lets the user overrule.)

**7. Legend symbols.**
- One `B` "creature" entry with a `species` param that spawns the scene. Rejected: a spawner level in every creature, and the map guide could not list each species.
- **Chosen:** one character per species; `B` is kept and repointed to the boar so the parser and reach fixtures (`room_map_parser_test`, `reach_grid_test`) keep working. The bait is `J` with an optional `stats` param, not a seventh symbol.

## Decision

### Files

```
resources/characters/enemies/enemy_stats.gd        EnemyStats (Resource)
resources/characters/enemies/enemy_move.gd         EnemyMove (Resource)
resources/characters/creatures/<species>/<species>_stats.tres, <species>_<move>.tres, <species>_locomotion.tres
resources/characters/creatures/scorpion/scorpion_bait_stats.tres

scenes/characters/enemies/enemy.gd                 Enemy (rewritten: composition root of a creature)
scenes/characters/enemies/enemy_ai.gd              EnemyAI (rewritten: the generic combat machine)
scenes/characters/enemies/move_clock.gd            MoveClock (RefCounted, pure)
scenes/characters/enemies/enemy_reach.gd           EnemyReach (static, pure)
scenes/characters/enemies/side_tracker.gd          SideTracker (RefCounted, pure; TURN_BAND commit)
scenes/characters/enemies/hit_guard.gd             HitGuard (static, pure; the crab's shell)
scenes/characters/enemies/ai/walker_ai.gd          WalkerAI
scenes/characters/enemies/ai/flyer_ai.gd           FlyerAI
scenes/characters/enemies/ai/ceiling_ai.gd         CeilingAI
scenes/characters/enemies/ai/thread_ai.gd          ThreadAI
scenes/characters/enemies/ai/swoop_path.gd         SwoopPath (RefCounted, pure)
scenes/characters/components/flight_component.gd   FlightComponent
scenes/characters/components/corruption/corruption_edge.gd          CorruptionEdge (Node)
scenes/characters/components/corruption/corruption_math.gd          CorruptionMath (static, pure)
scenes/characters/components/corruption/corruption_edge.gdshaderinc
scenes/characters/components/corruption/corruption_edge.gdshader
scenes/characters/creatures/<species>/<species>.tscn, <species>_animation_resolver.gd
scenes/characters/creatures/spider/silk_thread.gd, silk_thread.gdshader
```

Species scenes go under `scenes/characters/creatures/` because the art is under `assets/sprites/characters/creatures/` (assets mirror scenes) and CORE-04's teachers will sit beside them; the shared enemy framework stays in `scenes/characters/enemies/`.

### Data

`EnemyMove` (Resource): what one attack is. Shared names and units with `GuardianAttack`.
- `telegraph: float` s, standing (walkers) or holding position (flyers); the tell clip loops.
- `active: float` s, hitbox live; for a lunge, the longest run.
- `recovery: float` s (daze, stuck, recover).
- `cooldown: float` s, from the end of recovery.
- `reach: Rect2` px, relative to the feet (walkers) or the origin (flyers), authored facing east; the move starts only when the target is inside it.
- `lunge_speed: float` px/s during ACTIVE, along the facing (walkers) or the aim locked at the telegraph's end (flyers).
- `ends_on_wall: bool`: a wall or a ledge ends ACTIVE early and goes to RECOVER (the boar's daze).
- `armoured: bool`: during ACTIVE a hit neither knocks back nor cancels (the boar's charge).
- `hitbox: StringName`: the child `Hitbox` armed during ACTIVE.
- `damage: int`, `knockback_strength: float`, `knockback_lift: float` pushed into that hitbox at ACTIVE start.

`EnemyStats` (Resource): what a variant may change. Pushed by `Enemy` into its children at `_ready`, as `Guardian` pushes `GuardianStats`.
- `health: int`; `contact_damage: int`, `contact_knockback: float`.
- `sight_radius: float`, `wake_radius: float` (px; `Enemy` writes them into local-to-scene `CircleShape2D`s of `EnemySight` and `WakeTrigger`).
- `hidden_until_woken: bool`.
- `leash: float` px from home, 0 = none; `wanders: bool`; `stop_distance: float` (walkers park on horizontal distance, the brute's rule).
- `front_guard: bool` (hits from in front at body height are blocked).
- `locomotion: LocomotionStats` (pushed into `Locomotion` or `Flight`).
- `moves: Array[EnemyMove]`, in priority order: the first whose `reach` holds the target is thrown. Every species ships one move; a second is a data change, plus a clip const if it needs its own clip.
- wander and idle durations (folded from `EnemyAIStats`).
- `validate() -> PackedStringArray`: moves non-empty, durations positive, `hitbox` non-empty, a walker's `stop_distance` inside its move's reach.

Style-only tuning that no variant changes (`hover_distance`, `max_drop`, `descend_speed`, `always_face_target`) is an export on the style AI node in the species scene; the look (`rest_fray`, `hurt_fray`, `drift`, `frame_size`) is an export on `CorruptionEdge`. Neither belongs in `EnemyStats` (Interface Segregation).

Starting numbers (tune in playtest; the reach rule in Tests is binding, the numbers are not):

| Species | Style | hp | Move | telegraph / active / recovery / cooldown (s) | lunge px/s | Other |
|---|---|---|---|---|---|---|
| boar | walker | 4 | charge, `ends_on_wall`, `armoured` | 0.6 / 1.2 max / 1.0 daze / 0.8 | 300 | walk 60; wanders; hidden until woken |
| crab | walker | 3 | snap | 0.4 / 0.2 / 0.4 / 1.0 | 0 | sidestep 70; `front_guard`; `always_face_target` |
| bat | ceiling | 2 | swoop | 0.3 drop / path / return / 1.5 | path 220 | visible while dormant (hangs) |
| spider | thread | 2 | bite | 0.35 / 0.2 / 0.5 / 0.9 | 0 | descend 140, climb 80, `max_drop` 256; visible while dormant |
| hornet | flyer | 2 | dash | 0.5 / 0.45 / 0.6 / 1.2 | 380 | hover 90, `hover_distance` 128; wind bends the dash |
| scorpion | walker | 5 | strike | 0.7 / 0.2 / 0.8 stuck / 0.8 | 0 | no wander, leash 192, `Guard` tail |
| scorpion bait | walker | 8 | strike_bait | 0.55 / 0.2 / 0.6 / 0.5 | 0 | leash 320; sight 366, wake 200 (the lure tests) |

The one-shot attack clips (crab snap, scorpion strike, spider bite) are 4 frames at 20 fps = `active` 0.2, asserted with `Character._assert_clip_length` against `stats.moves[0].active`. Looping clips (charge, dash, swoop, tells) are not asserted.

### The body: `Enemy extends Character`

The composition root of a creature. Flat scene (depth 2 at most):

```
<Species> (CharacterBody2D, enemy.gd; exports save_id, stats, terminal_velocity)
  Sprite2D            scale.x -1 (art faces west), texture_filter NEAREST, material corruption_edge (resource_local_to_scene)
  CollisionShape2D
  Hurtbox             (hurtbox.tscn)
  ContactHitbox       Hitbox, continuous
  <Move>Hitbox        Hitbox, strikes_once; named by EnemyMove.hitbox
  Guard               Hitbox, continuous; scorpion only (the raised tail)
  AnimationPlayer / AnimationTree (flat, no transitions) / AnimationDriver / AnimationResolver (<Species>AnimationResolver)
  Health
  Locomotion | Flight
  AirflowBody         every species but the spider
  EnemySight          (+ RayCast2D at the eye, per species)
  WakeTrigger         PlayerProximityTrigger
  LedgeProbe          RayCast2D, walkers only
  AI                  WalkerAI | FlyerAI | CeilingAI | ThreadAI
  CorruptionEdge
  SilkThread          spider only
```

- **Wake.** Every creature starts dormant: the AI ignores presences, `steer` is zero, the resolver shows the dormant pose. `WakeTrigger.player_entered` (Ivo's body only, mask 256, as today) wakes it. With `hidden_until_woken` it is fully dissolved and its areas are off until `CorruptionEdge.appear()` finishes; otherwise it is drawn dormant (the bat as an icicle, the spider in the canopy). Physics stays on, the tree stays active from the start: nothing is keyed that needs hiding. This keeps the lure working: a shadow cast before Ivo wakes the scorpion is not acted on, and is the first presence it sees once woken.
- **Areas (script-owned, every physics frame in `_process_motion`, never inside a signal from the flush):** `Hurtbox.monitorable = is_present()` (woken, appeared, not dead); `ContactHitbox.monitoring = is_present()`; the current move's hitbox `monitoring = _ai.is_active()`; `Guard.monitoring = is_present() and not _ai.is_recovering()`.
- **Motion.** In knockback or dead: decay (both axes for a flyer). Else `_ai.tick(delta)`, `face_towards(_ai.facing_direction)`, then `Flight.fly_update(delta, _ai.steer, carry())`, or `Locomotion.ground_update(delta, _ai.steer.x / move_speed, carry().x)` and gravity. A lunge passes an axis above 1: `ground_update` targets `axis * move_speed`, so no shared component changes (comment it at the call). `FlightComponent.fly_update` steers the velocity toward `steer + wind * air_wind` with the `LocomotionStats` acceleration and deceleration (`architecture/one-air-channel`: input plus wind, never a force).
- **Sensors pushed into the AI** (the brute's `handle_wall_contact` pattern): `handle_wall_contact()` on a new wall contact; `handle_ledge()` when grounded and `LedgeProbe` (placed ahead of the feet on the facing side) finds no floor.
- **Hits.** `_on_hit_received`: if `stats.front_guard` and `HitGuard.blocks(facing, body_rect(), source.global_position)`, emit `blocked`, flash white, take nothing. Otherwise `super` (wound, flash), skipping knockback when the current move is `armoured` and active; then `_ai.on_hurt()` (cancels TELEGRAPH, and ACTIVE unless armoured; keeps the cooldown, the brute's `cancel_attack` rule).
- **Death.** `died` → `SaveSystem.mark_enemy_defeated(save_id)` (unchanged) and `CorruptionEdge.vanish()`; `_after_move` frees the body once `CorruptionEdge.is_gone()`. `Enemy` no longer asks the resolver for a death clip.
- **Hazards.** `receive_hazard` kills (a creature has no safe ground to return to). Walkers rarely meet one: the ledge probe stops them at a pit's lip.
- **Predicates** for the resolver and the playtest runner: `is_dormant()`, `is_present()`, `is_telegraphing()`, `is_attacking()` (ACTIVE), `is_recovering()`, `wants_to_move()`, `just_hit()`, `is_dead()`.
- **Layers** copied from the brute (body layer 65536, hitboxes mask 512, sight mask 768). Enemies do not collide with layer 4, so Redoma's shell stays matter-only.

### The AI: `EnemyAI extends AIController` plus four styles

`EnemyAI` holds what every species shares, ported from `BruteShadowAI` and the guardians:
- the target, chosen once per tick: `_sight.visible_presence()`;
- a `MoveClock` (pure): `start(move)`, `tick(delta)`, `phase` (READY, TELEGRAPH, ACTIVE, RECOVER, COOLDOWN), `end_active()` (a wall or a ledge), `cancel()` (keeps the cooldown);
- move selection: the first `stats.moves` entry whose `reach` holds the target (`EnemyReach.holds(reach, facing, origin, target)`), when the clock is READY;
- facing: a `SideTracker` keeps the side inside `TURN_BAND` (10 px); in reach and standing it faces the target; a move keeps the side it started on (the three brute bugs, now in one place);
- states DORMANT, IDLE, APPROACH, HOME, TELEGRAPH, ACTIVE, RECOVER, with `_select_state` choosing from the clock, the target and the leash;
- signals `move_telegraphed(move)`, `move_started(move)`, `move_finished(move)`, the `GuardianAI` names; `Enemy` connects them in code to `CorruptionEdge.agitate(on)`, and they are the hook for sounds later;
- `steer: Vector2` (px/s), `direction` = `signf(steer.x)`, `facing_direction`.

Each style overrides only the motion hooks `_idle_tick`, `_approach_tick`, `_home_tick`, `_active_tick`, `_recover_tick`:

| Style | Idle | Approach | Active | Recover / home | Species |
|---|---|---|---|---|---|
| `WalkerAI` | wander (when `wanders`) or hold home, turning to face a presence | horizontal chase to `stop_distance`, never past `leash` from home, stopped by `handle_ledge` | `facing * lunge_speed`; `ends_on_wall` ends on a wall or a ledge | stand (daze, stuck); then walk home when no target | boar, crab, scorpion |
| `FlyerAI` | hover at home on a slow bob | move to a point `hover_distance` from the target at its height | `aim * lunge_speed`, aim locked when the telegraph ends; `FlightComponent` adds the wind, so the current bends the dash | drift, then hover | hornet |
| `CeilingAI` | hang at the anchor | none: it waits until the target is inside the swoop's `reach` (below it) | follow a `SwoopPath` from its position through the target point locked at the end of the drop to the mirror point at the start height | fly back to the anchor, then hang | bat |
| `ThreadAI` | rest at the anchor | descend the thread toward the target's chest height while the target is in its column band, capped at `max_drop` and the floor | none (the bite reaches) | climb back after `linger` without a target | spider |

The anchor of a ceiling or thread creature is the top of its placed cell (legend anchor CENTER, origin minus half a cell); `room_files_test` holds that the cell above is solid. `SilkThread` draws a 2 px line from the anchor to the spider's top each frame and joins `CanvasPass.CREATURES`; its shader frays it into a dotted line on the same grid and clock (art pixels from a `VERTEX`-local varying, `greyhush_time`).

### The animation resolvers

One `<Species>AnimationResolver extends AnimationResolver` each, consts at the top, one ordered chain reading the `Enemy` predicates (`systems/animation`). The shape, for the boar:

```
dead -> HURT (held on its last frame while the body dissolves)
just_hit or holding(HURT), unless an armoured move is active -> HURT
dormant -> IDLE
telegraphing -> TELL
attacking -> CHARGE
recovering -> DAZE
wants_to_move -> WALK
-> IDLE
```

Per species: crab IDLE/SIDESTEP/TELL/SNAP/HURT (recover is IDLE); bat HANG (dormant, idle, home reached)/DROP (telegraph)/SWOOP/FLY (approach, recover, home)/HURT; spider IDLE (at the anchor)/CLIMB (moving on the thread)/BOB (holding, and the telegraph: it has no tell clip)/BITE/HURT; hornet HOVER/TELL/DASH/RECOVER/HURT; scorpion IDLE/WALK/TELL/STRIKE/STUCK/HURT. No resolver has a death or spawn const: the shader carries both.

### The corruption edge

`corruption_edge.gdshaderinc` (canvas_item, includes `dither_common.gdshaderinc`, declares `global uniform float greyhush_time`), used by `corruption_edge.gdshader` and later by guardians (02 §2: they share the glitch).

- **Grid.** The sprite's own art pixels: `art = floor(UV / TEXTURE_PIXEL_SIZE / 2.0)` (2 texels per art pixel), made frame-local with `frame_size` (the species' frame, constant across its clips) so a frame change does not re-roll the pattern. The grid travels with the body; it is neither `FRAGCOORD` nor screen pixels (the `life_note.gdshader` precedent: texel space). Use a floor-based modulo guarded against returning the divisor (`gotchas/glsl-floor-division-modulo-can-return-the-divisor`).
- **Edge.** An opaque art pixel's edge weight is 1 when a 4-neighbour at 1 art px is transparent, 0.5 at 2 art px, 0 deeper. Neighbours outside the current frame's rect read as transparent.
- **Fray.** A pixel deserts when `edge * (fray + agitation) > BAYER[index(art + offset(epoch))]`, `epoch = floor(greyhush_time / reroll_period + seed)`. An ordered dither, never a gradient.
- **Strays.** A transparent pixel draws the colour of the edge pixel `k` art px behind it along `-drift` (k 1..3) when a hash of that source and the epoch picks `k`: pixels leave the silhouette in the species' direction (boar bristles up, hornet wings back).
- **Dissolve.** `dissolve` 0..1 eats from the edge inward over the whole silhouette and multiplies the strays, so 1 draws nothing and 0 is unchanged.
- **Colour.** `texture(TEXTURE, UV) * COLOR`, so `Character.flash` (hurt, block) still shows. Premultiplied edges are left to `greyhush_creatures.gdshader`, which composites the pass.
- **Uniforms.** Per instance (the material is `resource_local_to_scene`): `fray`, `dissolve`, `agitation`, `seed`. Per species in the scene: `frame_size`, `drift`, `reroll_period` (0.25 s to start).
- No GDScript twin: the fray is rendering-only and gameplay never reads it (`systems/greyhush`: `MemoryFieldMath` has no twin of the wobble).

`CorruptionEdge` (Node) is the one writer of those uniforms. Exports `sprite` (NodePath), `rest_fray`, `hurt_fray`, `drift`, `frame_size`, `appear_time`, `vanish_time`. `_ready`: seed from the instance id, `CanvasPass.join_layer(body, CanvasPass.CREATURES)` (what the brute's shield did; corrupted creatures carry no `GreyhushShield`: colour reads as friend, grey and fraying as foe). `fray = CorruptionMath.fray(rest_fray, hurt_fray, current_hp, max_hp)` plus a hit spike decaying over 0.3 s, fed by `Health.damaged` (connected in the `.tscn`). `agitate(on)` sets `agitation` (the tell lives in the fraying, board: scorpion). `appear()` / `vanish()` tween `dissolve` with a pausable, scaled tween bound to the node; `is_gone()`, `is_appearing()`. Pause mode: inherit (pausable); nothing joins the ALWAYS list in `systems/songs-and-the-memorina`.

### Signals

| Signal | Emitter | Consumer |
|---|---|---|
| `player_entered` | `WakeTrigger` | `Enemy` (wake) |
| `damaged(amount, current)` | `Health` | `CorruptionEdge` (`.tscn` connection) |
| `died` | `Character` | `Enemy` (save, vanish) |
| `move_telegraphed` / `move_started` / `move_finished` | `EnemyAI` | `Enemy` (agitation; hitbox data at start); sounds later |
| `woken`, `blocked` | `Enemy` | nothing yet (sounds, playtest log) |
| `facing_changed` | `Character` | each `Hitbox` (`.tscn`, as today) |

One direction only: the AI reads its body's position and `EnemySight`; the body reads the AI; `CorruptionEdge` reads `Health` and is told by the body. Nothing reads `Input` or `SaveSystem` but `Enemy`'s existing `save_id` check.

### The legend (`resources/world/maps/room_legend.tres`)

It carries someone else's uncommitted changes. Exactly what changes, by step:
- **Step 2:** the `6_brute` ext_resource points at `res://scenes/characters/creatures/boar/boar.tscn`; the `brute` sub-resource becomes `boar` with description "Boar (Threshold): wanders; on sight paws the ground and charges in a straight line, dazed by a wall or a ledge. Needs a save_id unique across every map: it stays down until the next rest or death." Symbol `B`, kind ENTITY, anchor FEET, `required_params ["save_id"]`, reach role NONE (as today). New `J` scorpion, FEET, same params, description adding "Optional `stats`: `res://resources/characters/creatures/scorpion/scorpion_bait_stats.tres` for a territorial guard (A isca)."
- **Step 3:** `C` crab (FEET).
- **Step 4:** `N` hornet (CENTER), `A` bat (CENTER, "under a solid cell, open cells below").
- **Step 5:** `*` spider (CENTER, same rule). Check `*` passes `RoomLegend` validation and the parser; fall back to `Z`.
- Each step regenerates `docs/maps/README.md` (the `room-map` skill), with the editor closed (`gotchas/an-open-editor-reimports-rooms-with-its-old-importer`).
- Step 1 does not touch the legend, so it can land now. Steps 2-5 must not commit the other person's hunks: wait for them to commit, or stage only the creature hunks (`git add -p`). Edit the `.tres` by hand, never by an editor resave (`gotchas/scene-resave-buries-real-edits-in-noise`). Question 6.

No `FORMAT_VERSION` bump: the parser does not change. `EntityParams.apply` must load the `stats` path into the Resource export as it does `Door.requires`; verify when building step 2. `ReachWorldLoader` reads a root `stats` only to find `GuardianStats`, so an `EnemyStats` is ignored.

### Placements (16 in the world, 1 in a trial)

Rules for the room-map work: walkers on a floor run of at least 6 cells, the boar 8; none within 6 cells of a door's arrival point or a bench; ceiling creatures under solid with 5 clear cells below; none in a puzzle room except A isca; none in the village; none in arenas, the lighthouse rooms or rooms with a teacher (`woods_edge`, `lake_fishing_village`, `orchard_windy_gap`, `caldera_open_crater`). `save_id` = `<room>_<species>[_<n>]`; renaming ids costs nothing, since defeated enemies never reach the disk.

| Region | Room | Species | Count |
|---|---|---|---|
| threshold | `threshold_bridge` 31,4 (replaces `B`, save_id `threshold_bridge_boar`) | boar | 1 |
| frost_edge | `frost_shore` | crab | 2 |
| frost_edge | `frost_wreck_hold` | crab | 1 |
| frozen_lake | `lake_ice_caves` | bat | 2 |
| spring_woods | `woods_deep` | spider | 2 |
| spring_woods | `woods_canopy` | spider | 1 |
| wind_orchards | `orchard_chasm_bridge` | hornet | 2 |
| wind_orchards | `orchard_summit` | hornet | 1 |
| summer_caldera | `caldera_cistern_bottom` | scorpion | 1 |
| summer_caldera | `caldera_sun_stair` | scorpion | 2 |
| summer_caldera | `caldera_bait` 19,8 (replaces `B`; `id` `bait_scorpion`, save_id `caldera_bait_scorpion`, `stats` bait) | scorpion bait | 1 |
| trials_summer | `summer_trial` 53,15 (replaces `B`; `id` `lure_scorpion`, save_id `summer_trial_scorpion`, `stats` bait) | scorpion bait | 1 |

`threshold_fields` stays empty: Ivo crosses it before he owns the sword.

**Reachability audit:** no change. Every creature has reach role NONE, as `B` has; the audit neither anchors nor blocks on them, and no kit or allowlist entry moves. A creature never gates a way (design: fights are obstacles, not locks).

### Retiring the brute (in step 2, once B and J both exist)

Delete `scenes/characters/enemies/brute_shadow/` (scene, three scripts, uids), `resources/characters/enemies/brute_shadow/` (attack, AI and locomotion stats), `resources/characters/enemy_ai_stats.gd` (folded into `EnemyStats`), `assets/sprites/characters/enemies/brute_shadow/` (pack sheets and `.import`), the brute's `CREDITS.md` line, and `tests/scenes/characters/enemies/brute_shadow/brute_shadow_ai_test.gd` (its cases move to `walker_ai_test`). `playtest_runner.gd`'s `BruteShadow` branch becomes a generic `Enemy` line (`hp`, phase, `knocked`). Glossary: brute shadow → retired, replaced by the six species. Docs that name the brute: `systems/guardians` (reach section), `systems/animation`, `systems/world`, `docs/maps/README.md`, `tools/playtest/README.md`, `.claude/agents/godot-playtester.md`, the roadmap.

## Build order

1. **Pure helpers and the shader; no world change, no legend.** `EnemyMove`, `EnemyStats` (+ `validate`), `MoveClock`, `EnemyReach`, `SideTracker`, `HitGuard`, `SwoopPath`, `CorruptionMath` with their suites; `FlightComponent`; the corruption include, shader and `CorruptionEdge`. `Enemy`, `EnemyAI` and the brute stay untouched: the brute's clips key its areas under `RESET`, so porting it onto script-owned areas would be thrown away one step later.
2. **Body, walker, boar and scorpion; the brute retires.** `Enemy` and `EnemyAI` rewritten, `WalkerAI`; both walker scenes and resolvers, bait stats; legend `B` repointed and `J` added; the three placements moved; `combat_reach_test` and `summer_trial_test` moved to the new species; the brute deleted (list above); `world35s7_b2_bait_past_the_brute` and the bridge timelines re-run. The scorpion is in this step because two of the brute's three placements are lures.
3. **Crab** (front guard) and the remaining scorpion placements (`caldera_cistern_bottom`, `caldera_sun_stair`).
4. **Flyers:** `FlyerAI` + hornet, `CeilingAI` + bat; legend `N`, `A`; placements.
5. **Spider:** `ThreadAI`, `SilkThread`; legend `*`; placements.
6. **Docs:** new `systems/creatures` entry and its CLAUDE.md row; this entry's As built; the docs listed under Retiring; roadmap.

Each step passes `verify-gates`; steps 2-5 are playtested before they are committed.

## Tests (gdUnit4)

Pure first (`RefCounted` / static, mirroring source paths):
- `tests/scenes/characters/enemies/move_clock_test.gd`: phase order and durations; `end_active` goes to RECOVER; `cancel` keeps the cooldown; no start before READY.
- `enemy_reach_test.gd`: a rect mirrors with the facing; forward, overhead and below boxes; edge inclusion.
- `side_tracker_test.gd`: holds inside `TURN_BAND`, turns outside it.
- `hit_guard_test.gd`: front blocked, behind and above not, both facings.
- `tests/scenes/characters/enemies/ai/swoop_path_test.gd`: starts at the start, passes the target at the midpoint, ends at the mirror point, duration from speed.
- `tests/scenes/characters/components/corruption/corruption_math_test.gd`: fray rises as hp falls, clamped 0..1; dissolve endpoints.
- `tests/resources/characters/enemies/enemy_stats_test.gd`: every shipped `EnemyStats` under `resources/characters/creatures/` validates; a bad one reports.

Nodes:
- `walker_ai_test.gd`: the six brute cases ported (faces a target in reach, keeps a move's side, turns without walking in the cooldown, parks at `stop_distance` on x only, a jump from the parking spot does not draw it under, a near-overhead ledge does not flip it), plus: a ledge stops the chase, a wall ends a charge into RECOVER, the leash walks it home, a dormant walker ignores a presence, a shadow presence (not Ivo) is targeted.
- `flyer_ai_test.gd` (aim locked at the telegraph's end; wind carried), `ceiling_ai_test.gd` (waits until the target is under it; returns to the anchor), `thread_ai_test.gd` (descends to the target's height, capped; climbs back after `linger`).
- `tests/scenes/characters/enemies/enemy_test.gd`: areas off while dormant-hidden and dead; contact on once present; `Guard` off in RECOVER; an armoured active move takes no knockback; a front-guarded hit is blocked; a defeated `save_id` frees on ready; the body frees only after the dissolve.
- `combat_reach_test.gd`: for every species scene, its move's `Hitbox` touches a grounded Ivo across its move's whole `reach` (the guardian rule, on static shapes); for each walker, Ivo's slash and chop land on it parked at `stop_distance` (the brute rule, swing 1's slide included) and `stop_distance` is outside its contact reach.
- `tests/scenes/characters/creatures/creature_sheet_test.gd`: each clip's sheet width is hframes x the species frame width and its height the frame height (from the contracts); `hframes` is keyed before `frame`; no clip keys any `Area2D` property; no tree has a transition; the resolver's consts name exactly the tree's states.
- `summer_trial_test.gd`: reads `wake_radius` and `sight_radius` from the bait `EnemyStats` and the `lure_scorpion` id.
- `room_files_test.gd`: every `A` and `*` hangs under solid with 5 clear cells below; no creature in `home_village`; no creature in a puzzle room but `caldera_bait`; save ids unique (existing test).
- `tools/smoke/scenes.txt`: the six species scenes.
- The `verify-gates` shader scan already refuses `TIME` and `FRAGCOORD`.

## Playtest timelines (`tools/playtest/scripts/`)

- `core13_boar_bridge.json`: approach the bridge, wait out the tell, jump the charge, punish the daze; a charge toward the gap dazes at the ledge.
- `core13_scorpion_bait.json`: A isca by the shadow and by the fight; strike, stuck, punish; a pogo on the raised tail hurts.
- `core13_crab_shore.json`: front hits blocked, a pogo on the shell lands, a hit from behind lands.
- `core13_bat_ice_caves.json`, `core13_hornet_orchards.json` (a dash across a current), `core13_spider_woods.json` (pogo off the bobbing spider).
- Re-run and rename the brute screenshots: `traverse_opening_e_bridge_gap`, `bench_rest_and_death`, `map_open_at_death`, `map_closed_by_hit`, `world35s7_b2_bait_past_the_brute`.
- The report must say what screenshots cannot: whether each weak clip reads with its timing and fray, the latency between tell and strike, and whether the fray reads at 0.05 memory (Frost Edge) and at 0.4 (woods).

## i18n

No user-facing string. Creatures have no names on screen, no notebook entry and no HUD; legend descriptions are developer docs. If a bestiary is ever wanted it is a new feature with its own keys.

## SOLID check

- Species as scene + `EnemyStats`, the bait as a `.tres`: Open/Closed (a variant is data) and Single Responsibility (`Enemy` composes, the AI decides, the motor moves).
- Four movement styles as `EnemyAI` subclasses overriding motion hooks only: Liskov (each is a drop-in `AIController` for `Enemy`) and Open/Closed (a fifth style is a new file).
- `MoveClock`, `EnemyReach`, `SideTracker`, `HitGuard`, `SwoopPath`, `CorruptionMath` pure: Single Responsibility, and the brute's three bugs pinned once.
- Script-owned areas, clips that only draw: Single Responsibility between gameplay and rendering; no `RESET` trap.
- Style-only and look-only tuning on their own nodes, not in `EnemyStats`: Interface Segregation.
- `Enemy` depends on `AIController` and two motor components by role, not on species: Dependency Inversion.

## Consequences

- Every new creature is a scene and a resolver; never a subclass of `Enemy`.
- Hitboxes on creatures are never keyed; a reviewer should refuse an `Area2D` track in a creature clip (`creature_sheet_test` does).
- Guardians can adopt `corruption_edge.gdshaderinc` without changing it.
- `EnemyAI` changes for every species at once; its suite must cover the shared rules, not one species.
- Death no longer has a clip: a creature with a drawn death would need its resolver back on `is_death_finished()`.

## Questions for the user (each with the default this plan uses)

1. **Seen before it wakes?** Default: the boar, crab, scorpion and hornet gather out of the grey when Ivo comes near (the brute's behaviour, now as a dissolve); the bat and spider are drawn while dormant, because their ambush is the read (an icicle, a body in the canopy).
2. **Placement and density:** the 16 placements above (1 boar, 3 crabs, 2 bats, 3 spiders, 3 hornets, 3 scorpions plus the bait). Default: yes.
3. **A blocked hit on the crab's shell:** default no damage and a white flash on the crab, with no recoil on Ivo (a recoil means a `Player` change).
4. **How much tougher the bait scorpion is:** default 8 hp (5), telegraph 0.55 s (0.7), stuck 0.6 s (0.8), cooldown 0.5 s (0.8), same damage (1).
5. **The fray through a song's freeze:** default it keeps re-rolling on `greyhush_time` while the creature stands frozen, as the greyhush edge does; the alternative stops it with the body.
6. **`room_legend.tres` has someone else's uncommitted changes.** Default: step 1 goes ahead now; before step 2 ask them to commit, else stage only the creature hunks with `git add -p`.
7. **Touching a creature hurts** (1 damage, as the brute's body did). Default: yes, for all six.

## User decisions (2026-10-29)

1. Waking: "Gather out of the grey (Recommended)": boar, crab, scorpion and hornet form out of the grey (the dissolve reversed) when Ivo comes near; the bat and spider are drawn asleep.
2. Contact and shell: "1 damage; shell blocks (Recommended)": touching any creature costs 1; a hit on the crab's shell does no damage, flashes it white, no recoil on Ivo.
3. Bait scorpion: "Faster and sturdier (Recommended)": 8 hp, telegraph 0.55 s, stuck 0.6 s, cooldown 0.5 s, same damage.
4. The rest: "Accept (Recommended)": the 16 placements plus the trial lure; the fray keeps flickering on `greyhush_time` during a song's freeze; `room_legend.tres` may be committed on top of its uncommitted changes (Godot editor re-save of defaults only).

## As built: round 1 (2026-10-29)

Build order steps 1 and 2: the boar and the scorpion (and its bait), the generic body and machine, the brute retired. The entry is [`systems/creatures`](../systems/creatures.md). Round 2 built the rest (below).

Built as planned: `EnemyMove`, `EnemyStats` (+ `validate`), `MoveClock`, `EnemyReach`, `SideTracker`, `CorruptionMath`, `FlightComponent` (tested, unused until the flyers), `corruption_edge.gdshaderinc` / `.gdshader` / `CorruptionEdge`, `Enemy` and `EnemyAI` rewritten, `WalkerAI`, `boar.tscn` and `scorpion.tscn` with their resolvers, `scorpion_bait_stats.tres`; legend `B` repointed to the boar and `J` added; the three brute placements moved (`threshold_bridge_boar`; `bait_scorpion` / `caldera_bait_scorpion` and `lure_scorpion` / `summer_trial_scorpion`, both with the bait stats); the brute's scene, scripts, sheets and stats deleted, with `brute_shadow_ai_test` ported to `walker_ai_test`; `playtest_runner.gd` prints a generic `Enemy` line.

Deviations, and why:
- **Not built in round 1:** `HitGuard`, `SwoopPath`, the `front_guard` field and the `blocked` signal: they serve the crab and the bat (round 2). The step-3 scorpion placements (`caldera_cistern_bottom`, `caldera_sun_stair`) wait for step 3.
- **Shader layout.** Custom shader functions cannot read `TEXTURE`, and passing `TEXTURE` as a `sampler2D` argument fails in the shader compiler, so the include's samplers are macros (`CE_ALPHA`, `CE_COLOUR`, `CE_EDGE`) and the fragment body lives in `corruption_edge.gdshader`. A guardian adopting the edge includes the file and copies that fragment. Godot's preprocessor substitutes a macro parameter inside a member access (`a` in `.a`), so the parameters are named `CE_O` and `CE_P`.
- **Clip length check.** The scorpion's strike clip equals `stats.moves[0].active`, asserted by `creature_sheet_test` instead of `Character._assert_clip_length` at startup, because `Enemy` names no clip and a resolver hook only for the assert was not worth a base class.
- **The ledge is a property.** `EnemyAI.ledge_ahead` is written by the body every physics frame (continuous input is a property, CLAUDE.md), instead of a `handle_ledge()` call; walls stay a discrete `handle_wall_contact()`.
- **The AI ticks through knockback** while the creature is present; only the steer waits for the knockback to end. With the brute's rule (no tick in knockback) every hit would pause the daze clock and a combo could hold the boar dazed for ever.
- **`CorruptionEdge` connects `Health.damaged` in code** through its `health` export, not in the `.tscn`.
- **Numbers.** Clip rates: idle 6 fps, walk 10, tell 10 (scorpion 8), charge 12, daze and stuck 6, hurt 10, strike 20. Shapes come from the strips' opaque bounds: boar body 50x30, hurtbox 56x34, contact 46x26, charge box 22x22 at x 24; scorpion body 40x24, hurtbox 42x24, contact 36x20, strike box 28x26 at x 24, `Guard` 24x32 over the tail (y -60..-28). The scorpion's strike art never leaves its body, so its reach is short: x 0..46, stop distance 36 (contact reach 29). Boar: charge reach x 0..192, stop distance 56 (contact reach 33). Sight radii: boar 320, scorpion 280, bait 366; wake 200 for all.
- **Timelines.** New `core13_boar_bridge.json` and `core13_scorpion_bait.json` (unplayed scaffolds: times are estimates for the playtester to tune). The brute-era screenshots were renamed (`e*_boar`, `00_open_creature_awake`, `02_creature`, `b22_over_the_scorpion`) and `world35s7_b2_bait_past_the_brute.json` became `world35s7_b2_bait_past_the_scorpion.json`; the `core09_brute_*` and `core11_brute_running_reach` timelines are left as the record of those playtests.
- **Docs not touched** (outside this change's scope by instruction): `docs/roadmap.md`, `.claude/agents/godot-playtester.md` (brute positions) and `.claude/skills/pixellab/SKILL.md` (cites `brute_shadow.tscn`).

## As built: round 2 (2026-10-29)

Build order steps 3 to 6: the crab and the remaining scorpion placements, the hornet and the icicle bat, the spider, the docs. All 16 world placements and the trial lure are in.

Built as planned: `HitGuard`, `SwoopPath`, `EnemyStats.front_guard`, `Enemy.blocked`; `FlyerAI`, `CeilingAI`, `ThreadAI`; `crab.tscn`, `hornet.tscn`, `bat.tscn`, `spider.tscn` with their resolvers, stats, moves and locomotion; `SilkThread` and `silk_thread.gdshader`; legend `C`, `N`, `A`; the plan's placements; suites `hit_guard_test`, `swoop_path_test`, `flyer_ai_test`, `ceiling_ai_test`, `thread_ai_test`, new cases in `enemy_test`, `combat_reach_test` and `room_files_test`; the four scenes in `tools/smoke/scenes.txt`; draft timelines `core13_crab.json`, `core13_hornet.json`, `core13_bat.json`, `core13_spider.json`, each starting inside the wake radius of a placed creature.

Deviations, and why:
- **The spider is `Z`, not `*`.** `*` is the reach board's "leads nowhere" mark (`ReachFinding.MARKS`), and `reach_grid_test` refuses a legend symbol that is a board mark; the plan named `Z` as the fallback.
- **The third spider's room.** `woods_canopy` has no solid ceiling over open air (its top is sky), so the spider hangs under the launch branch (a one-way, cols 9-14, row 4) with 3 open cells to the floor. The hanging rule is per symbol: a bat under a solid cell with 5 open cells below (room to swoop), a spider under ground or a one-way with 3 (it only lets itself down over Ivo). Both `woods_deep` spiders also hang from branches: that room has no ceiling over its climb either.
- **The spider's origin is its body's centre**, not its feet (`Sprite2D.position.y` -11): with its feet at the cell centre (the CENTER anchor) its art reached 10 px into the cell above. `ThreadAI.chest_height` is 0 on the spider.
- **`SilkThread` is top level at the anchor**, so its art-pixel grid is tied to the ceiling and does not slide along the thread as the spider moves; it joins the creature pass through the body's `CanvasPass.join_layer` (which walks the children), not by a call of its own. Its fray is a material constant (0.2), not a uniform `CorruptionEdge` writes; it hides at death while the body dissolves.
- **No drawn descent on the drop.** The bat holds still through its 0.3 s telegraph (the drop clip), so the swoop starts at the anchor; `combat_reach_test` flies the swoop from there.
- **Flyer reach is measured flown.** A dash or a swoop moves its hitbox, so the static-box check of the walkers would not say whether it lands. `combat_reach_test` flies each one frame by frame through `FlightComponent.steered` from the AI's own steer (`FlyerAI.aim_at`, `CeilingAI.swoop_steer`) and requires a touch on an Ivo standing at each corner of the reach (the round-1 reviewer's rule for a reach top, extended to a reach bottom). The bite, a standing move, is checked at the reach's top and bottom over its whole x range.
- **Two small changes to the shared machine.** `EnemyAI` gained `_enter_phase(phase)` (where a style locks an aim or a path), `is_home()`, `CHEST`, and a facing dead band (`FACE_DEADBAND`, 12 px/s): a flyer settling on a point steers a little each frame and flipped on every sign change. Walkers steer 0 or a full speed, so their facing is unchanged. `Enemy` wakes a creature on a hit (a bat or spider struck asleep) and passes the wind only once a creature is awake (a hanging bat stays put).
- **Numbers.** Shapes come from the strips' opaque bounds. Crab: body 36x22, hurtbox 40x26, contact 30x18 (centred), snap box 20x22 at x 16; reach x 0..32, y -16..8; stop 28 (contact reach 23). Hornet: body 22x18, hurtbox 28x24, dash box 30x20; dash active 0.5 s (the plan's 0.45 fell short of the reach once the 2400 px/s^2 acceleration is flown), reach x 0..160, y -8..48 from its centre; `air_wind` 0.6, so it holds its point against a 150 px/s current. Bat: body 24x20, hurtbox 32x24, swoop box 36x22; path speed 240 (the plan's 220 made a 200 px dive last 1.8 s), active 2.5 s as a cap (the path's end ends it); wake 224 (it hangs about 180-210 px over the floor it guards). Spider: body 20x20, hurtbox 26x22, bite box 18x16 at x 16; reach x 0..30, y 5..37 from its centre.
- **Placements.** `frost_shore` crabs at cols 10 and 26 (8 cells from the breach door), `frost_wreck_hold` on the bow run (col 15, row 6); `lake_ice_caves` bats at 6,2 and 34,3 (the only ceiling cells with 5 open cells over the floor: the shelf and the hump block the others); `woods_deep` spiders under the row-11 and row-15 branches of the east climb; `orchard_chasm_bridge` hornets over the east floor, `orchard_summit` over the east slope; `caldera_cistern_bottom` scorpion between the pit and the dais; `caldera_sun_stair` scorpions on the L shelf at row 21 and the R shelf at row 27. The sun stair has the plate and gate of Verao Espacial 1 on its floor; the plan placed two scorpions there and the user accepted the placements, so they stand on the shelves far above it.
- **Docs not touched** (outside this change's scope by instruction): `docs/roadmap.md`, `.claude/agents/godot-playtester.md`.
